"""Sequential, bounded validation. A passing package is not engine/release acceptance."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from build_identity import identity, package_project, source_hashes

ROOT = Path(__file__).resolve().parents[1]

def digest_sources():
    return source_hashes(ROOT)

def contracts():
    failures = []
    def code_only(text):
        text = re.sub(r'--\[(=*)\[.*?\]\1\]', '', text, flags=re.S)
        return re.sub(r'--[^\n]*', '', text)
    sources = {p: code_only(p.read_text(encoding='utf-8-sig')) for p in (ROOT/'src').rglob('*.lua')}
    remote_source = (ROOT/'src/shared/Remotes.lua').read_text(encoding='utf-8')
    declared = set(re.findall(r'^[ \t]*"([A-Za-z]+)",',remote_source,re.M))
    for p, s in sources.items():
        for name in re.findall(r'Remotes\.Get\(["\']([^"\']+)["\']\)',s):
            if name not in declared: failures.append(f'{p.relative_to(ROOT)}: undeclared remote {name}')
        if re.search(r'Instance\.new\(["\'](?:Sound|AudioPlayer|AudioEmitter|AudioDeviceInput)["\']\)',s):
            failures.append(f'{p.relative_to(ROOT)}: experience audio creation is forbidden')
        if 'AudioCatalog' in s or 'PlaySound' in s: failures.append(f'{p.relative_to(ROOT)}: obsolete audio pipeline')
        if re.search(r'weapon\.vfx\s*==',s) and 'server' in p.parts:
            failures.append(f'{p.relative_to(ROOT)}: visual identifier determines gameplay')
    # Verify literal cross-service calls against actual exported functions/aliases.
    exports = {}
    for p,s in sources.items():
        exports[p.stem] = set(re.findall(r'function\s+\w+\.([A-Za-z_]\w*)\s*\(',s)) | set(re.findall(r'^\w+\.([A-Za-z_]\w*)\s*=',s,re.M))
    for p,s in sources.items():
        for owner,method in re.findall(r'\b([A-Za-z]\w*Service)\.([A-Za-z_]\w*)\s*\(',s):
            if owner in exports and method not in exports[owner]: failures.append(f'{p.relative_to(ROOT)}: missing {owner}.{method}')
    return sorted(set(failures))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--tools-dir',default=os.environ.get('FLORIDA_MAN_TOOLS',str(Path(os.environ.get('LOCALAPPDATA','.'))/'FloridaMan/toolchain')))
    parser.add_argument('--output',default='artifacts/validation')
    parser.add_argument('--no-package',action='store_true')
    args=parser.parse_args()
    out=(ROOT/args.output).resolve(); out.mkdir(parents=True,exist_ok=True)
    lock=ROOT/'.validation.lock'
    try: fd=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY)
    except FileExistsError: raise SystemExit('Another validator holds .validation.lock; do not run builds concurrently.')
    os.write(fd,str(os.getpid()).encode()); os.close(fd)
    started=time.time(); report={'started':started,'passed':False,'sourceStable':False,'engineAcceptance':'not-performed-by-this-validator','checks':[]}
    tools=Path(args.tools_dir)
    def run(label,argv,timeout=60):
        result=subprocess.run([str(x) for x in argv],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout)
        output=result.stdout+result.stderr
        (out/(re.sub(r'[^a-zA-Z0-9_-]','_',label)+'.txt')).write_text(output,encoding='utf-8')
        record={'name':label,'exitCode':result.returncode}
        report['checks'].append(record)
        print(f'{label}: {"PASS" if result.returncode==0 else "FAIL"}',flush=True)
        return result.returncode==0
    try:
        # Invalidate any previous success before work that can raise. A failed
        # rerun must never leave a stale passing report beside an old package.
        (out/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
        report['tools']=json.loads((ROOT/'scripts/toolchain.json').read_text())
        before=digest_sources(); report['sourceHashes']=before
        report['buildIdentity']=identity(before)
        report['gitRevision']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
        compile_ok=True
        for p in sorted((ROOT/'src').rglob('*.lua'))+sorted((ROOT/'tests').rglob('*.luau')):
            compile_ok=run('compile_'+str(p.relative_to(ROOT)),[tools/'luau-0.737/luau-compile.exe','--null',p]) and compile_ok
        failures=contracts(); (out/'contracts.json').write_text(json.dumps(failures,indent=2))
        report['checks'].append({'name':'contracts','exitCode':int(bool(failures))})
        if compile_ok:
            run('sourcemap',[tools/'rojo/rojo.exe','sourcemap','default.project.json','-o',out/'sourcemap.json'])
            run('roblox_types',[tools/'luau-lsp-1.69.0/luau-lsp.exe','analyze','--platform=roblox',f'--sourcemap={out / "sourcemap.json"}',f'--definitions={tools / "luau-lsp-1.69.0/globalTypes.d.luau"}','src'])
            for test in sorted((ROOT/'tests').glob('*.test.luau')):
                run('test_'+test.stem,[tools/'luau-0.737/luau.exe',test])
        if not args.no_package and all(c['exitCode']==0 for c in report['checks']):
            packaged_project=out/'package.project.json'
            packaged_project.write_text(json.dumps(package_project(ROOT,before),indent=2),encoding='utf-8')
            run('package',[tools/'rojo/rojo.exe','build',packaged_project,'-o',out/'FloridaMan.rbxlx'])
            package=out/'FloridaMan.rbxlx'
            if package.exists(): report['packageSha256']=hashlib.sha256(package.read_bytes()).hexdigest()
        after=digest_sources()
        report['sourceStable']=before==after
        report['passed']=report['sourceStable'] and all(c['exitCode']==0 for c in report['checks'])
        report['engineAcceptance']='not-performed-by-this-validator'
        report['elapsedSeconds']=round(time.time()-started,2)
        print(f'Validation {"PASS" if report["passed"] else "FAIL"}; report: {out / "report.json"}')
        return 0 if report['passed'] else 1
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        report['passed']=False
        report['error']=f'{type(error).__name__}: {error}'
        print(f'Validation FAIL: {report["error"]}',flush=True)
        return 1
    finally:
        report['elapsedSeconds']=round(time.time()-started,2)
        try:
            (out/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
        finally:
            lock.unlink(missing_ok=True)

if __name__=='__main__': sys.exit(main())

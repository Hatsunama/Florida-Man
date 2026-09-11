"""Build an isolated, manually operated QA place from an unchanged validated baseline.

Uses installed pinned tools only. Never launches Studio, alters provider settings,
edits default.project.json, or publishes anything.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
from build_identity import package_project, identity, source_hashes as manifest

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / 'qa/StudioAudit.luau'
BRIDGE = ROOT / 'qa/StudioAuditBridge.server.lua'
CLIENT = ROOT / 'qa/StudioClientAudit.client.lua'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_hashes():
    return manifest(ROOT)


def normalize_sourcemap(node, project_directory):
    # Rojo emits paths relative to the derived project; LSP resolves them from cwd.
    if 'filePaths' in node:
        node['filePaths'] = [(project_directory / path).resolve().as_posix() for path in node['filePaths']]
    for child in node.get('children', []):
        normalize_sourcemap(child, project_directory)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tools-dir', required=True, type=Path)
    parser.add_argument('--output', default='artifacts/studio-audit', type=Path, help='Separate output directory.')
    parser.add_argument('--validation-report', default='artifacts/validation-final/report.json', type=Path)
    args = parser.parse_args()
    tools = args.tools_dir.resolve()
    output = (ROOT / args.output).resolve()
    validation_path = (ROOT / args.validation_report).resolve()
    if (output / 'report.json').resolve() == validation_path:
        raise SystemExit('QA output must differ from the baseline validation directory; preserve its report.')
    output.mkdir(parents=True, exist_ok=True)
    report = {'passed': False, 'engineAcceptance': 'not-executed', 'checks': [],
              'baselineValidation': str(validation_path), 'defaultProjectModified': False}
    lock = ROOT / '.validation.lock'
    try:
        fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        raise SystemExit('Another validator holds .validation.lock; run this builder sequentially.')
    os.write(fd, str(os.getpid()).encode())
    os.close(fd)

    def run(label, arguments):
        result = subprocess.run([str(arg) for arg in arguments], cwd=ROOT, capture_output=True,
                                text=True, encoding='utf-8', errors='replace', timeout=60)
        (output / f'{label}.txt').write_text(result.stdout + result.stderr, encoding='utf-8')
        report['checks'].append({'name': label, 'exitCode': result.returncode})
        print(f'{label}: {"PASS" if result.returncode == 0 else "FAIL"}', flush=True)
        if result.returncode != 0:
            raise RuntimeError(f'{label} failed; see {output / (label + ".txt")}')

    try:
        (output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        baseline = json.loads(validation_path.read_text(encoding='utf-8'))
        expected = {key.replace('\\', '/'): value for key, value in baseline.get('sourceHashes', {}).items()}
        if not baseline.get('passed') or not baseline.get('sourceStable') or source_hashes() != expected:
            raise RuntimeError('A passing validation report matching every current source/test/project hash is required. Run scripts/validate.py first.')
        report.update({'baselineReportSha256':sha256(validation_path), 'sourceHashes':expected,
                       'qaSha256':sha256(QA), 'bridgeSha256':sha256(BRIDGE), 'clientQaSha256':sha256(CLIENT), 'builderSha256':sha256(Path(__file__))})
        project = package_project(ROOT,expected)
        if any(name in project['tree']['ServerScriptService'] for name in ['StudioAudit','StudioAuditBridge','StudioAuditCommand']):
            raise RuntimeError('Default project already maps QA; keep QA isolated.')
        if 'StudioClientAudit' in project['tree']['StarterPlayer']['StarterPlayerScripts']:
            raise RuntimeError('Default project already maps client QA; keep QA isolated.')
        report['buildIdentity']=identity(expected)
        project['name'] += '-StudioAudit'
        project['tree']['ServerScriptService']['StudioAudit'] = {'$path': QA.as_posix()}
        project['tree']['ServerScriptService']['StudioAuditBridge'] = {'$path': BRIDGE.as_posix()}
        project['tree']['StarterPlayer']['StarterPlayerScripts']['StudioClientAudit'] = {'$path': CLIENT.as_posix()}
        project_path = output / 'studio-audit.project.json'
        project_path.write_text(json.dumps(project, indent=2), encoding='utf-8')
        run('compile_qa', [tools / 'luau-0.737/luau-compile.exe', '--null', QA])
        run('compile_bridge', [tools / 'luau-0.737/luau-compile.exe', '--null', BRIDGE])
        run('compile_client_qa', [tools / 'luau-0.737/luau-compile.exe', '--null', CLIENT])
        sourcemap = output / 'sourcemap.json'
        run('sourcemap_qa', [tools / 'rojo/rojo.exe', 'sourcemap', project_path, '-o', sourcemap])
        sourcemap_data = json.loads(sourcemap.read_text(encoding='utf-8'))
        normalize_sourcemap(sourcemap_data, project_path.parent)
        sourcemap.write_text(json.dumps(sourcemap_data), encoding='utf-8')
        run('types_qa', [tools / 'luau-lsp-1.69.0/luau-lsp.exe', 'analyze', '--platform=roblox',
                        f'--sourcemap={sourcemap}', f'--definitions={tools / "luau-lsp-1.69.0/globalTypes.d.luau"}', QA, BRIDGE, CLIENT])
        if source_hashes() != expected or sha256(QA) != report['qaSha256'] or sha256(BRIDGE) != report['bridgeSha256'] or sha256(CLIENT) != report['clientQaSha256']:
            raise RuntimeError('Sources changed during QA checks; rerun baseline validation and QA build.')
        package = output / 'FloridaMan-StudioAudit.rbxlx'
        run('package_qa', [tools / 'rojo/rojo.exe', 'build', project_path, '-o', package])
        report['sourceStable'] = source_hashes() == expected and sha256(QA) == report['qaSha256'] and sha256(BRIDGE) == report['bridgeSha256'] and sha256(CLIENT) == report['clientQaSha256']
        report['defaultProjectModified'] = sha256(ROOT / 'default.project.json') != expected['default.project.json']
        report['packageSha256'] = sha256(package)
        report['passed'] = report['sourceStable'] and not report['defaultProjectModified']
        if not report['passed']:
            raise RuntimeError('Sources changed during packaging; this QA package is not validated.')
        print(f'QA package: {package}\nRuntime/Studio acceptance: NOT EXECUTED.')
        return 0
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as error:
        report['passed'] = False
        report['error'] = str(error)
        print(error)
        return 1
    finally:
        try:
            (output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        finally:
            lock.unlink()


if __name__ == '__main__':
    raise SystemExit(main())

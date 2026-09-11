"""Small stdio MCP client for the preinstalled official StudioMCP executable.

Does not enable permissions, install plugins, publish, or select an unknown Studio.
Only use tool schemas returned by tools/list. All calls target an explicitly selected instance.
"""
import argparse
import json
import os
from pathlib import Path
import queue
import subprocess
import threading
import sys

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--exe',required=True)
    parser.add_argument('--method',default='tools/list')
    parser.add_argument('--params-file')
    parser.add_argument('--output',default='artifacts/studio-mcp-result.json')
    parser.add_argument('--timeout',type=int,default=30)
    args=parser.parse_args()
    process=subprocess.Popen([args.exe],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,encoding='utf-8',creationflags=(subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0))
    messages=queue.Queue()
    def read():
        for line in process.stdout:
            try: messages.put(json.loads(line))
            except ValueError: pass
    threading.Thread(target=read,daemon=True).start()
    def call(identifier,method,params):
        process.stdin.write(json.dumps({'jsonrpc':'2.0','id':identifier,'method':method,'params':params})+'\n');process.stdin.flush()
        while True:
            response=messages.get(timeout=args.timeout)
            if response.get('id')==identifier:return response
    try:
        init=call(1,'initialize',{'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'FloridaManLocalVerification','version':'1.0'}})
        if 'error' in init: raise RuntimeError(init['error'])
        process.stdin.write(json.dumps({'jsonrpc':'2.0','method':'notifications/initialized'})+'\n');process.stdin.flush()
        params=json.loads(Path(args.params_file).read_text(encoding='utf-8-sig')) if args.params_file else {}
        result=call(2,args.method,params)
        out=Path(args.output);out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,indent=2),encoding='utf-8')
        print(json.dumps(result,ensure_ascii=False))
    finally:
        process.terminate()
        try:process.wait(timeout=3)
        except subprocess.TimeoutExpired:process.kill()

if __name__=='__main__':main()

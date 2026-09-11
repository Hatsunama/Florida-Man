"""Bind local packages to source hashes without editing the shared checkout."""
import hashlib
import json
from pathlib import Path


def source_hashes(root: Path):
    files = sorted((root / 'src').rglob('*.lua')) + sorted((root / 'tests').rglob('*.luau'))
    files += sorted((root / 'scripts').glob('*.py')) + sorted((root / 'scripts').glob('*.ps1'))
    files += sorted((root / '.github/workflows').glob('*.yml'))
    files += [root / 'default.project.json', root / 'scripts/toolchain.json']
    return {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}


def identity(source_hashes):
    return hashlib.sha256(json.dumps(source_hashes, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def package_project(root: Path, source_hashes):
    project = json.loads((root / 'default.project.json').read_text(encoding='utf-8'))

    def absolute(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key == '$path':
                    node[key] = (root / value).resolve().as_posix()
                else:
                    absolute(value)

    absolute(project)
    project['tree']['ReplicatedStorage']['BuildIdentity'] = {
        '$className': 'StringValue', '$properties': {'Value': identity(source_hashes)}
    }
    return project

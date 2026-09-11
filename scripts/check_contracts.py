from validate import contracts
import sys

failures = contracts()
for failure in failures:
    print('FAIL ' + failure)
print(f'Contract check: {len(failures)} failure(s). Compilation, types and behavior require validate.py.')
sys.exit(bool(failures))

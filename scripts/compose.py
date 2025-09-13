#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(".")
COMPOSE_ROOT = BASE_DIR / "compose"
ENV_FILE = BASE_DIR / ".env"
ENV_FILE_PROD = BASE_DIR / ".env.prod"

def get_compose_files(target: str, env: str):
    """
    Return a list of docker-compose files based on the folder structure:
    - up compose_folder -> all yml files in that folder
    - up compose_folder/file -> only that file
    """
    parts = target.split("/", 1)
    folder = COMPOSE_ROOT / parts[0]

    if not folder.exists() or not folder.is_dir():
        print(f"Error: Folder {folder} does not exist in compose/")
        sys.exit(1)

    # User specified a specific file
    if len(parts) == 2:
        file_base = parts[1]
        # Prefer prod if env=prod, fallback to normal
        file_path = folder / f"{file_base}.prod.yml" if env == "prod" else folder / f"{file_base}.yml"
        
        base_file_path = None
        
        if env == "prod":
            # fallback to dev file
            base_file_path = folder / f"{file_base}.yml"
            
            if not base_file_path.exists():
                print(f'Error: prod compose file {file_path} does not exist')
            
        if not file_path.exists():
            print(f"Error: Compose file {file_path} does not exist")
            sys.exit(1)
            
        if base_file_path:
            return [base_file_path, file_path]
            
        return [file_path]

    # User specified the whole folder -> all files
    if env == "prod":
        files = list(folder.glob("*.yml"))
        
        if not files:
            print(f"No prod compose files found in {folder}")
            sys.exit(1)
            
        files.sort()
        files.reverse()
    else:
        files = [f for f in folder.glob("*.yml") if not f.name.endswith(".prod.yml")]
        if not files:
            print(f"No compose files found in {folder}")
            sys.exit(1)

    return files

def run_compose(action: str, target: str, env: str, dry: bool):
    files = get_compose_files(target, env)
    env_file = ENV_FILE_PROD if env == "prod" else ENV_FILE

    cmd = ["docker", "compose"]
    if env_file.exists():
        cmd += [f"--env-file={env_file}"]

    for f in files:
        cmd += ["-f", str(f)]

    cmd.append(action)
    if action == "up":
        cmd.append("-d")
    elif action == 'down':
        cmd.append("--remove-orphans")

    if dry:
        cmd = " ".join(cmd)
        print(f"Command to execute: ")
        print(cmd)
        return
        
    print("Running:", " ".join(cmd))
    
    try:
        subprocess.run(cmd, check=True)
        print(f"{action} completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error running docker compose {action}: {e}")
        sys.exit(1)

def main():
    valid_commands = [
        'up', 'down', 'ps', 'logs'
    ]
    
    dry = True if '--dry' in sys.argv else False
    
    if '--dry' in sys.argv:
        sys.argv.remove('--dry')
    
    if len(sys.argv) < 3 or sys.argv[1] not in valid_commands:
        print("Usage: python compose.py [up|down] <target> [prod]")
        print("Examples:")
        print("  python compose.py up infra")
        print("  python compose.py up infra prod")
        print("  python compose.py up infra/traefik")
        print("  python compose.py down services")
        print("  python compose.py up services/whoami")
        
        sys.exit(1)
        
    action = sys.argv[1]
    target = sys.argv[2]
    env = sys.argv[3] if len(sys.argv) > 3 else "dev"

    run_compose(action, target, env, dry)

if __name__ == "__main__":
    main()

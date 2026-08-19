import os
from pathlib import Path


def rename_to_lowercase(folder: Path, apply: bool) -> int:
    if not folder.exists() or not folder.is_dir():
        raise SystemExit(f"Folder not found: {folder}")

    files = [p for p in folder.iterdir() if p.is_file()]
    if not files:
        print("No files found.")
        return 0

    planned = []
    for p in files:
        new_name = p.name.lower()
        if new_name != p.name:
            planned.append((p, folder / new_name))

    if not planned:
        print("Nothing to rename (all filenames already lowercase).")
        return 0

    # Проверка конфликтов (файл с таким именем уже существует)
    conflicts = [(src, dst) for (src, dst) in planned if dst.exists() and dst != src]
    if conflicts:
        print("Conflicts found (will be skipped):")
        for src, dst in conflicts:
            print(f"  SKIP: {src.name} -> {dst.name} (already exists)")
        print()

    renamed = 0
    for src, dst in planned:
        if dst.exists() and dst != src:
            continue

        if not apply:
            print(f"WOULD RENAME: {src.name} -> {dst.name}")
            continue

        # 2-step rename для Windows (чтобы сработало даже если меняется только регистр)
        tmp = src.with_name(src.name + ".__tmp__case__")
        if tmp.exists():
            raise SystemExit(f"Temp name already exists: {tmp.name}")

        os.rename(src, tmp)
        os.rename(tmp, dst)
        print(f"RENAMED: {src.name} -> {dst.name}")
        renamed += 1

    if apply:
        print(f"\nDone. Renamed: {renamed}, Total candidates: {len(planned)}")
    else:
        print(f"\nDry-run done. Candidates: {len(planned)}")
    return renamed


if __name__ == "__main__":
    folder = Path(r"C:\D\!!!DZ\Delphi-Andro\WIN\WORKPATH\dicts")
    rename_to_lowercase(folder, apply=True)

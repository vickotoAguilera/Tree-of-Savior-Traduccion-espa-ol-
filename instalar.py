#!/usr/bin/env python3
"""Instalador de la traduccion al espanol de Tree of Savior (Steam).

Crea la carpeta languageData/Spanish copiando tu languageData/English y reemplazando solo
la columna de texto en ingles por el espanol. No modifica English/ ni ningun otro archivo del
juego. Solo usa la biblioteca estandar de Python 3.8+.

  python instalar.py                 instala (busca el juego en la ruta de Steam por defecto)
  python instalar.py --juego RUTA    ruta a ...\\TreeOfSavior\\release\\languageData
  python instalar.py --desinstalar   borra la carpeta Spanish
  python instalar.py --activar       ademas pone Spanish como idioma en user.xml/client.xml
"""
import argparse
import re
import shutil
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
PARCHE = AQUI / "parche"
RUTAS = [
    r"C:\Program Files (x86)\Steam\steamapps\common\TreeOfSavior\release\languageData",
    r"C:\Program Files\Steam\steamapps\common\TreeOfSavior\release\languageData",
    r"D:\SteamLibrary\steamapps\common\TreeOfSavior\release\languageData",
]
NO_TRADUCIR = {"BADWORDS.tsv"}


def buscar_juego(arg):
    for r in ([arg] if arg else RUTAS):
        p = Path(r)
        if (p / "English").is_dir():
            return p
    return None


def cargar_parche(nombre):
    trans = {}
    f = PARCHE / f"{nombre}.es.tsv"
    texto = f.read_bytes().decode("utf-8").replace("\r\n", "\n")
    for linea in texto.split("\n")[1:]:
        if linea:
            rid, _, txt = linea.partition("\t")
            trans[rid] = txt
    return trans


def aplicar(src_bytes, trans):
    """Reemplaza solo la columna 2 de las filas cuyo ID esta en `trans`."""
    out, n = [], 0
    for raw in src_bytes.split(b"\n"):
        cr = raw.endswith(b"\r")
        cols = (raw[:-1] if cr else raw).split(b"\t")
        rid = cols[0].decode("utf-8", "replace")
        if len(cols) >= 2 and rid in trans:
            cols[1] = trans[rid].encode("utf-8")
            n += 1
        out.append(b"\t".join(cols) + (b"\r" if cr else b""))
    return b"\n".join(out), n


def activar(release):
    for nombre, patron, nuevo in (
        ("user.xml", r'(<Config\b[^>]*?\bLanguage=")[^"]*(")', r"\1Spanish\2"),
        ("client.xml", r'(DefaultLanguage=")[^"]*(")', r"\1Spanish\2"),
    ):
        f = release / nombre
        if f.is_file():
            t = f.read_text("utf-8")
            n = re.sub(patron, nuevo, t, count=1)
            if n != t:
                shutil.copyfile(f, f.with_name(nombre + ".bak_spanish"))
                f.write_text(n, "utf-8")
                print(f"  {nombre}: idioma = Spanish (copia: {nombre}.bak_spanish)")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--juego", help="ruta a la carpeta languageData del juego")
    ap.add_argument("--desinstalar", action="store_true")
    ap.add_argument("--activar", action="store_true")
    a = ap.parse_args()

    lang = buscar_juego(a.juego)
    if not lang:
        print("No encontre el juego. Indica la carpeta con --juego "
              r'"C:\...\TreeOfSavior\release\languageData"')
        return 1
    dst = lang / "Spanish"

    if a.desinstalar:
        if dst.is_dir():
            shutil.rmtree(dst)
            print(f"Borrada {dst}. Si el juego estaba en Spanish, elige otro idioma en los Ajustes.")
        else:
            print("No hay carpeta Spanish instalada.")
        return 0

    if not PARCHE.is_dir():
        print("Falta la carpeta 'parche' junto a instalar.py.")
        return 1
    print(f"Juego: {lang}\nCierra Tree of Savior antes de instalar.")
    shutil.copytree(lang / "English", dst, dirs_exist_ok=True)
    for f in sorted(PARCHE.glob("*.es.tsv")):
        nombre = f.name[: -len(".es.tsv")]
        if f"{nombre}.tsv" in NO_TRADUCIR:
            continue
        src = lang / "English" / f"{nombre}.tsv"
        if not src.is_file():
            print(f"  {nombre}: no existe en tu juego, omitido")
            continue
        datos, n = aplicar(src.read_bytes(), cargar_parche(nombre))
        (dst / f"{nombre}.tsv").write_bytes(datos)
        print(f"  {nombre}: {n} textos traducidos")
    if a.activar:
        activar(lang.parent)
    print("\nListo. Abre el juego y elige Spanish en Ajustes > Seleccionar idioma (reinicia el juego).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

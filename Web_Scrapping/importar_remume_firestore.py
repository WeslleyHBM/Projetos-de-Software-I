from __future__ import annotations

import argparse
import csv
import os
import re
import unicodedata
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def normalizar_texto(valor: str) -> str:
    texto = unicodedata.normalize("NFKD", valor.strip().lower())
    texto = texto.encode("ascii", "ignore").decode("ascii")
    texto = re.sub(r"[^a-z0-9]+", "-", texto)
    return re.sub(r"-+", "-", texto).strip("-")


def gerar_id_documento(nome: str, concentracao: str, forma_farmaceutica: str) -> str:
    base = "-".join(
        [
            normalizar_texto(nome),
            normalizar_texto(concentracao),
            normalizar_texto(forma_farmaceutica),
        ]
    )
    return base or "medicamento"


def inicializar_firestore(service_account_path: Path) -> firestore.Client:
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(service_account_path))
        firebase_admin.initialize_app(cred)
    return firestore.client()


def importar_csv(csv_path: Path, collection_name: str, service_account_path: Path) -> int:
    db = inicializar_firestore(service_account_path)
    collection_ref = db.collection(collection_name)

    total = 0
    batch = db.batch()
    operacoes_no_lote = 0

    with csv_path.open("r", encoding="utf-8-sig", newline="") as arquivo_csv:
        leitor = csv.DictReader(arquivo_csv)

        for linha in leitor:
            nome = (linha.get("Nome") or "").strip()
            concentracao = (linha.get("Concentração") or "").strip()
            forma_farmaceutica = (linha.get("Forma Farmacêutica") or "").strip()
            componente = (linha.get("Componente") or "").strip()
            nome_normalizado = normalizar_texto(nome)
            componente_normalizado = normalizar_texto(componente) if componente else ""

            if not nome:
                continue

            documento_id = gerar_id_documento(nome, concentracao, forma_farmaceutica)
            documento_ref = collection_ref.document(documento_id)

            batch.set(
                documento_ref,
                {
                    "nome": nome,
                    "nomeNormalizado": nome_normalizado,
                    "concentracao": concentracao,
                    "formaFarmaceutica": forma_farmaceutica,
                    "componente": componente,
                    "componenteNormalizado": componente_normalizado,
                    "fonte": csv_path.name,
                },
            )
            total += 1
            operacoes_no_lote += 1

            if operacoes_no_lote == 500:
                batch.commit()
                batch = db.batch()
                operacoes_no_lote = 0

    if operacoes_no_lote:
        batch.commit()

    return total


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Importa o CSV da REMUME para o Firestore."
    )
    parser.add_argument(
        "--csv",
        dest="csv_path",
        default="remume_santa_maria.csv",
        help="Caminho do arquivo CSV de origem.",
    )
    parser.add_argument(
        "--collection",
        default="remume_santa_maria",
        help="Nome da coleção no Firestore.",
    )
    parser.add_argument(
        "--service-account",
        default=os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "serviceAccountKey.json"),
        help="Caminho do JSON da service account do Firebase.",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv_path).expanduser().resolve()
    service_account_path = Path(args.service_account).expanduser().resolve()

    if not csv_path.exists():
        raise FileNotFoundError(f"CSV não encontrado: {csv_path}")

    if not service_account_path.exists():
        raise FileNotFoundError(
            f"JSON da service account não encontrado: {service_account_path}"
        )

    total = importar_csv(csv_path, args.collection, service_account_path)
    print(
        f"Importação concluída: {total} linhas enviadas para a coleção '{args.collection}'."
    )


if __name__ == "__main__":
    main()
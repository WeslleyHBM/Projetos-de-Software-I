from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
import time
import csv

options = webdriver.ChromeOptions()

# evita detecção de bot
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("--start-maximized")

driver = webdriver.Chrome(options=options)

driver.get("https://famurs.com.br/remume")

time.sleep(5)

# selecionar município
select = Select(driver.find_element(By.NAME, "municipio"))
select.select_by_value("366")

time.sleep(2)

# clicar pesquisar
driver.find_element(By.XPATH, "//button[contains(text(),'Pesquisar')]").click()

time.sleep(8)  # mais tempo pra garantir

dados = []

print("🔄 Tentando capturar dados...")

# DEBUG forte
print(driver.page_source[:2000])

# pega QUALQUER div visível com texto
cards = driver.find_elements(By.XPATH, "//div")

print("Total de divs:", len(cards))

dados = []
vistos = set()

print("🔄 Limpando dados...")

for card in cards:
    texto = card.text.strip()

    # ignora coisas inúteis do site
    if (
        not texto or
        "Oportuniza" in texto or
        "Selecione" in texto or
        "Início" in texto or
        "Lista de Medicamentos" in texto
    ):
        continue

    if "Concentração:" not in texto:
        continue

    linhas = texto.split("\n")

    nome = linhas[0].strip()
    concentracao = ""
    forma = ""
    componente = ""

    for linha in linhas:
        if "Concentração:" in linha:
            concentracao = linha.split(":")[1].strip()
        elif "Forma Farmacêutica:" in linha:
            forma = linha.split(":")[1].strip()
        elif "Componente:" in linha:
            componente = linha.split(":")[1].strip()

    # cria chave única pra evitar duplicado
    chave = (nome, concentracao, forma, componente)

    if chave not in vistos:
        vistos.add(chave)
        dados.append([nome, concentracao, forma, componente])

driver.quit()

# salvar CSV
with open("remume_santa_maria.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["Nome", "Concentração", "Forma Farmacêutica", "Componente"])
    writer.writerows(dados)

print("🎉 Finalizado com", len(dados), "registros!")
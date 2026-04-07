from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select, WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import csv

# Configurações do Chrome
options = webdriver.ChromeOptions()
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("--start-maximized")

# Inicializa o Driver
driver = webdriver.Chrome(options=options)

# --- DECLARAÇÃO DO WAIT (A biblioteca que estava faltando) ---
# O '20' é o tempo máximo que ele vai esperar antes de dar erro
wait = WebDriverWait(driver, 20) 

# Acessa o site
driver.get("https://famurs.com.br/remume")

try:
    # 1. Selecionar Município (Santa Maria - ID 366)
    select_el = wait.until(EC.presence_of_element_located((By.NAME, "municipio")))
    Select(select_el).select_by_value("366")
    time.sleep(2)

    # 2. Clique robusto no botão Pesquisar via JavaScript
    btn_pesquisar = driver.find_element(By.XPATH, "//button[contains(text(),'Pesquisar')]")
    driver.execute_script("arguments[0].click();", btn_pesquisar)
    time.sleep(8)
    dados = []
    vistos = set()

    print("🚀 Aguardando resultados do REMUME...")

    while True:
        # Espera carregar o primeiro medicamento (pela tag strong fsize12em do seu print)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "strong.fsize12em")))
        
        # Pausa para garantir que o texto da "Forma Farmacêutica" carregou no HTML
        time.sleep(3) 

        # Pega todos os cards de medicamentos
        cards = driver.find_elements(By.CSS_SELECTOR, "div.well.mb10")
        
        if not cards:
            break

        # Guarda o nome do primeiro item para saber quando a página mudar de fato
        primeiro_nome_antes = cards[0].find_element(By.CSS_SELECTOR, "strong.fsize12em").text
        
        print(f"📦 Processando {len(cards)} itens nesta página...")

        for card in cards:
            try:
                # Extração dos campos
                nome = card.find_element(By.CSS_SELECTOR, "strong.fsize12em").text.strip()
                
                concentracao = "Não informado"
                forma = "Não informado"
                componente = "Não informado"

                # Busca as linhas de detalhe (p class="nomargin")
                linhas = card.find_elements(By.CSS_SELECTOR, "p.nomargin")
                for linha in linhas:
                    texto_completo = linha.text.strip()
                    if ":" in texto_completo:
                        partes = texto_completo.split(":", 1)
                        rotulo = partes[0].lower()
                        valor = partes[1].strip()

                        if "concentra" in rotulo:
                            concentracao = valor
                        elif "forma" in rotulo:
                            forma = valor
                        elif "componente" in rotulo:
                            componente = valor

                # Adiciona à lista se for novo
                chave = (nome, concentracao, forma, componente)
                if chave not in vistos:
                    vistos.add(chave)
                    dados.append([nome, concentracao, forma, componente])
            except:
                continue

        # --- Lógica para ir para a Próxima Página ---
        try:
            # Localiza o link 'Próxima' na paginação
            link_proxima = driver.find_element(By.XPATH, "//ul[contains(@class, 'pagination')]//a[contains(text(), 'Próxima')]")
            li_pai = link_proxima.find_element(By.XPATH, "./parent::li")

            # Verifica se o botão está desabilitado (fim da lista)
            if "disabled" in li_pai.get_attribute("class"):
                print("✅ Fim da lista alcançado.")
                break

            # Scroll e clique
            driver.execute_script("arguments[0].scrollIntoView();", link_proxima)
            time.sleep(1)
            driver.execute_script("arguments[0].click();", link_proxima)
            print("➡️ Indo para a próxima página...")

            # Espera o conteúdo da página mudar antes de reiniciar o loop
            wait.until(lambda d: d.find_element(By.CSS_SELECTOR, "strong.fsize12em").text != primeiro_nome_antes)
            
        except Exception:
            print("🏁 Não foi possível encontrar mais páginas.")
            break

    # 3. Salvar os dados em CSV
    if dados:
        arquivo = "remume_santa_maria.csv"
        with open(arquivo, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["Nome", "Concentração", "Forma Farmacêutica", "Componente"])
            writer.writerows(dados)
        print(f"\n🎉 Sucesso! {len(dados)} medicamentos salvos em {arquivo}")

finally:
    driver.quit()

# Minha Cantina - Aplicação Móvel Flutter 📱🛒

Aplicação móvel multiplataforma (**Android, iOS, Web, Linux, macOS, Windows**) do sistema **Minha Cantina** (Mercadorias e Pequena Mercearia de Conveniência / *Small Grocery Store* em Angola), desenvolvida com **Flutter (Dart 3, Material 3)** seguindo a arquitetura **MVVM + Repository**.

---

## 🔄 Auto-Push Automático

Este repositório possui auto-push configurado em `.githooks/post-commit`.
Para comitar e enviar alterações com um só comando:
```bash
./autopush.sh "sua mensagem de commit"
```
Ou ao fazer qualquer `git commit -m "..."`, o envio para o GitHub é acionado automaticamente!

---

## ✨ Funcionalidades Principais

* **Catálogo de Mercearia com Pesquisa:** Navegação por artigos essenciais (*Mercearia, Óleos & Enlatados, Lacticínios & Matabicho, Bebidas, Higiene & Limpeza, Biscoitos*), unidades de medida (`kg`, `litro`, `lata`, `pct`, `un`), pesquisa por texto/código de barras e cesto de compras.
* **Chave de Levantamento Presencial (OTP):**
  * Geração e exibição em destaque de código OTP de 6 dígitos (ex: `4 8 2 9 1 0`).
  * **QR Code Dinâmico:** Gerado diretamente pelo `qr_flutter` para leitura imediata pelo leitor do balconista na cantina.
  * **Temporizador Regressivo em Tempo Real:** Indicador visual de prazo limite com garantia de devolução dos artigos ao stock e estorno integral para a carteira.
* **Carteira Digital & Recargas:**
  * Exibição de saldo em Kwanzas (`AOA / Kz`).
  * Modal de carregamento via **Multicaixa Express**, **Transferência Bancária / BAI Directo** (com botão para copiar o IBAN da cantina) e **Depósito**.
  * **Extrato do Livro-Razão (*Ledger*):** Auditoria de cada débito, crédito ou estorno com transparência de saldo anterior e posterior.
* **Balcão da Cantina (Terminal do Balconista):**
  * Terminal do operador da cantina para inserção do código OTP ou leitura do QR Code.
  * Validação instantânea de estado da reserva e conferência das mercadorias antes da entrega final ao cliente (`PICKED_UP`).
* **Seletor de Conexão com Backend:**
  * Permite alternar dinamicamente entre **Localhost (8080)**, **Emulador Android (10.0.2.2)** e **Produção no Render (`https://minha-cantina-api.onrender.com`)**.
  * Modo de demonstração com mock state reativo caso o backend esteja offline.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* Flutter SDK (3.24+ ou 3.44+)
* Dart 3+
* Emulador Android, dispositivo físico ou navegador Google Chrome

### 1. Obter dependências
```bash
flutter pub get
```

### 2. Conectar ao Backend no Render (Produção)
```bash
flutter run --dart-define=API_URL=https://minha-cantina-api.onrender.com
```

### 3. Conectar ao Backend Local
* **No Navegador Web / Desktop:**
  ```bash
  flutter run -d chrome
  ```
* **No Emulador Android Oficial:**
  O emulador conecta automaticamente ao host através de `http://10.0.2.2:8080`.
  ```bash
  flutter run
  ```

---

<!-- Live continuous auto-push active -->

---

## 🧪 Testes
Para executar a suite de testes automatizados:
```bash
flutter test
```

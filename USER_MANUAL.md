
---

#### 📄 `USER_MANUAL.md`

```markdown
# 📘 Manual do Usuário - TV RH Automático

## 📺 Como funciona?

A TV exibe imagens automaticamente em looping. O time de RH tem autonomia total para:

✅ Adicionar fotos
✅ Remover fotos
✅ Alterar a velocidade de transição

---

## 📂 Acessar a pasta

No Windows, abra o Explorador de Arquivos e digite:
\\10.0.2.16\TV


**Credenciais:**
- **Usuário:** `tvuser`
- **Senha:** `[informada pela TI]`

---

## 📸 Adicionar imagens

1. Acesse a pasta
2. **Arraste** as imagens para dentro
3. Aguarde 1 minuto para a TV atualizar

**Formatos:** JPG, PNG, GIF, WEBP

---

## ⏱️ Controlar a velocidade

1. Na pasta, abra o arquivo `config.txt` com Bloco de Notas
2. Altere o número:
TEMPO_ENTRE_IMAGENS = 5 ← 5 segundos
TEMPO_ENTRE_IMAGENS = 30 ← 30 segundos
TEMPO_ENTRE_IMAGENS = 60 ← 1 minuto


3. Salve e aguarde

**Valores:** Entre 1 e 300 segundos

---

## 🗑️ Remover imagens

1. Acesse a pasta
2. Selecione as imagens
3. Pressione **Delete**

---

## 🎯 Dicas

- Para controlar ordem, use números: `01_aviso.jpg`, `02_comunicado.png`
- Mantenha imagens na resolução da TV (1920x1080)
- Evite GIFs grandes

---

## 🆘 Suporte

**Contato da TI:**
- E-mail: ti@empresa.com
- Ramal: 1234

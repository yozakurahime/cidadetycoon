Coloque aqui as imagens dos veiculos pelo nome do modelo.

Exemplos:
- sultanrs.webp
- elegy.webp
- urus.webp
- nzp.webp

Regras:
- formato recomendado: WEBP
- tamanho recomendado: 420x220 (ou proporcao similar)
- nome do arquivo deve ser igual ao model do veiculo (minusculo)

Se nao houver imagem local, o sistema usa:
1) mapeamento de ui/vehicle_images.json
2) fallback visual automatico

Automacao:
- Execute fill_images.ps1 para preencher arquivos automaticamente.
- No jogo:
  /tycoon_capture_model <model>
  /tycoon_capture_missing_models
  (requer screenshot-basic iniciado)

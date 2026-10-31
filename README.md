# Brumavale — RPG sandbox para Roblox Studio

Brumavale é uma base jogável e original de RPG sandbox, criada inteiramente com primitivas do Roblox e instalada por um único script da Command Bar. O jogo traz progressão, economia, inventário, fabricação, mercado entre jogadores do servidor, coleta, combate PvE, missões, cinco regiões e interface para computador e celular.

## Instalação no Roblox Studio

1. Abra uma experiência no Roblox Studio e pare qualquer teste em execução.
2. Abra **Exibir (View) → Command Bar**.
3. Abra [Brumavale.commandbar.lua](dist/Brumavale.commandbar.lua), copie o arquivo inteiro, cole na Command Bar e pressione **Enter** uma vez.
4. Aguarde a mensagem `BRUMAVALE v2 instalado!` no Output e pressione **Play**.
5. Salve ou publique a experiência pelo Studio quando estiver satisfeito.

O instalador funciona offline e não usa modelos, plugins, IDs de assets, HTTP ou módulos de terceiros. Ele só cria objetos dentro dos namespaces `Brumavale`. Uma reinstalação preserva a versão anterior em `ServerStorage/BrumavaleBackup_*`. Se encontrar um objeto de outra origem com um desses nomes, ele para sem sobrescrevê-lo.

Se uma versão anterior já estiver instalada, pare o teste, execute novamente o instalador completo e depois inicie um novo Play. A versão 2 verifica explicitamente que tanto o servidor quanto o `LocalScript` da interface foram ativados.

## O que já funciona

- Cidade segura **Porto Bruma** e quatro regiões: Prados do Sol, Bosque Âmbar, Pedreira Cinzenta e Ruínas da Aurora.
- 33 pontos de recursos, 14 inimigos, chefe guardião, respawn e IA simples.
- Combate validado pelo servidor, ataque básico, corte em área, defesa, cura e perda de 10% da prata ao cair.
- Mochila com limite de peso, armas, armaduras, consumíveis e equipamento visual.
- Coleta, refino, nove receitas, níveis, XP e quatro contratos progressivos.
- Mercador com preços fixos e mercado de ofertas entre jogadores do mesmo servidor, com reserva dos itens e taxa de venda.
- Interface responsiva em português, HUD, inventário, fabricação, comércio, mapa, jornada e câmera isométrica opcional.
- Salvamento com DataStore e proteção de sessão em servidores publicados. Dentro do Studio, os perfis são temporários por escolha, evitando alterar dados reais durante testes.

## Controles

| Ação | Computador | Celular |
| --- | --- | --- |
| Mover | WASD | Joystick do Roblox |
| Interagir/coletar/viajar | E | Prompt na tela |
| Ataque básico | Clique no inimigo ou botão **Atacar** | Botão **Atacar** |
| Corte em área | Q | Botão **Corte** |
| Usar poção | R | Botão **Poção** |
| Inventário | I | Botão **Bolsa** |
| Fabricação | C | Interaja com a forja |
| Mapa | M | Botão **Mapa** |
| Câmera isométrica | V | Botão **Câmera** |

Para comprar, vender, fabricar, anunciar ou resgatar um contrato, aproxime-se da banca correspondente em Porto Bruma. Os portais também exigem proximidade; todas essas regras são verificadas pelo servidor.

## Desenvolvimento e validação

Os fontes separados ficam em `src/`; [build.py](tools/build.py) gera novamente o instalador offline. Com o interpretador e compilador oficiais do Luau disponíveis:

```bash
python3 tools/build.py
python3 tools/check.py --luau /caminho/para/luau --compiler /caminho/para/luau-compile
```

As verificações locais compilam cada script e o instalador final, conferem se o bundle está atualizado, executam 28 testes de transações da economia, 7 testes do salvamento com um DataStore simulado e verificam o bootstrap dos scripts de servidor e cliente. A aparência, os prompts, a integração real com DataStore e o fluxo multiplayer ainda precisam de um teste final dentro do Roblox Studio, pois este ambiente de desenvolvimento não inclui o Studio.

## Escopo desta versão

O mercado é local ao servidor e não é uma bolsa global. A proteção de sessão evita que dois servidores editem o mesmo perfil, mas uma compra entre duas contas não é uma transação distribuída resistente a falha abrupta. Esta primeira versão também não inclui PvP, guildas, montarias, ilhas pessoais ou masmorras instanciadas.

O projeto usa uma identidade, mapa, nomes e interface próprios. Ele reproduz o gênero e os principais ciclos de um sandbox RPG sem copiar assets, textos ou marca de outro jogo.

# Exportar APK para Android

O preset `Android` exporta um APK de depuração assinado, adequado para instalar e testar no
celular. Ele não usa chave de publicação da Google Play.

## Requisitos

O Godot do projeto é a versão 4.7.2. Instale e configure:

- OpenJDK 17.
- Android SDK Platform-Tools 35 ou mais recente.
- Android SDK Build-Tools 35.0.1 e Platform 35.
- Android SDK Command-line Tools (latest), NDK 28.1.13356709 e CMake 3.10.2.4988404.
- Export templates correspondentes ao Godot 4.7.2.

O guia oficial do [Godot 4.7 para exportar no Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
detalha a instalação do JDK, SDK, pacotes requeridos e caminhos em Editor Settings. O SDK também
pode ser instalado pelo Android Studio ou `sdkmanager`; a instalação pede aceitar as licenças do
Android SDK.

## Exportar

1. Abra o projeto no Godot 4.7.2 e confira em **Editor > Editor Settings > Export > Android** os
   caminhos do Java SDK e Android SDK.
2. O preset `Android` já está no projeto. Exporte-o como depuração pelo editor ou rode no PowerShell:

   ```powershell
   & $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --export-debug Android C:\Jogos\rpg\builds\android\dnd_in_a_piece.apk
   ```

3. Instale `builds/android/dnd_in_a_piece.apk` no celular e teste o analógico, pulo, ataque,
   Fôlego, Surto e o toggle de Mente Tática.

O APK atual foi exportado e assinado para depuração. Os testes automatizados exercitam o toque,
mas ainda é necessário conferir a sensação dos controles num aparelho físico.

O preset habilita arm64 e arm32. Para publicar na Google Play, configure uma chave de lançamento
própria e exporte um AAB; não compartilhe uma chave privada no repositório.

## Quando o jogo fecha sozinho no celular

O jogo guarda uma caixa-preta (`RegistroDeFalhas`). Se ele fechar sem o jogador sair, na próxima
abertura aparece "O jogo fechou sozinho da última vez" por cima do título: toque em **Copiar** e
mande o texto. Ele traz os últimos passos (fase, telas, nível, escolhas) e o fim de
`user://logs/godot.log` daquela vez. Com cabo USB e depuração ligada, `adb logcat` mostra também
quedas nativas que o log do Godot não pega.

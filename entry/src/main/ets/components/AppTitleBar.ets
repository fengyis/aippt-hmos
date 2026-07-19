@ComponentV2
export struct AppTitleBar {
  @Param title: string = ''
  @Param showBack: boolean = true
  @Param showRightIcon: boolean = false
  @Param rightIconSymbol: Resource = $r('sys.symbol.magnifyingglass')
  @Event onBackClick: () => void = () => {}
  @Event onRightClick: () => void = () => {}

  build() {
    Row() {
      if (this.showBack) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([Color.Black])
          .onClick(() => this.onBackClick())
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1C')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      if (this.showRightIcon) {
        SymbolGlyph(this.rightIconSymbol)
          .fontSize(22)
          .fontColor([Color.Black])
          .onClick(() => this.onRightClick())
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
}

@CustomDialog
@ComponentV2
export struct ConfirmDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: ConfirmDialog({}) })
  @Param title: string = '提示'
  @Param message: string = ''
  @Param confirmText: string = '确认'
  @Param cancelText: string = '取消'
  @Event onConfirm: () => void = () => {}
  @Event onCancel: () => void = () => {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172939')
        .margin({ bottom: 8 })
      Text(this.message)
        .fontSize(14)
        .fontColor('#868686')
        .margin({ bottom: 20 })
      Row() {
        Button(this.cancelText)
          .fontSize(14)
          .fontColor('#1C1C1C')
          .backgroundColor('#E6E3FF')
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => {
            this.onCancel()
            this.controller.close()
          })
        Button(this.confirmText)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#5B3CFF')
          .borderRadius(20)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm()
            this.controller.close()
          })
      }
      .width('100%')
    }
    .padding(24)
    .borderRadius(12)
    .backgroundColor(Color.White)
  }
}

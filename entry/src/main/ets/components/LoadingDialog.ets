@CustomDialog
@ComponentV2
export struct LoadingDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: LoadingDialog({}) })
  @Param message: string = '加载中...'

  build() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#5B3CFF')
      Text(this.message)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 12 })
    }
    .padding(24)
    .borderRadius(12)
    .backgroundColor(Color.White)
  }

  show(message?: string) {
    if (message) {
      this.message = message
    }
    this.controller.open()
  }

  close() {
    this.controller.close()
  }
}

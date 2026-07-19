@ComponentV2
export struct PptTemplateCard {
  @Param coverUrl: string = ''
  @Param templateName: string = ''
  @Param borderRadius: number = 10
  @Event onClick: () => void = () => {}

  build() {
    Column() {
      Image(this.coverUrl)
        .width('100%')
        .aspectRatio(3 / 4)
        .borderRadius(this.borderRadius)
        .objectFit(ImageFit.Cover)
      Text(this.templateName)
        .fontSize(14)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width('100%')
    .onClick(() => this.onClick())
  }
}

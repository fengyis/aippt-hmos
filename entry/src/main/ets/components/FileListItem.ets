@ComponentV2
export struct FileListItem {
  @Param fileIcon: Resource = $r('app.media.ic_file_default')
  @Param fileName: string = ''
  @Param fileDes: string = ''
  @Param timeCategory: string = ''
  @Param showCategory: boolean = false
  @Param keyword: string = ''
  @Event onClick: () => void = () => {}

  build() {
    Row() {
      Image(this.fileIcon)
        .width(40)
        .height(40)
        .borderRadius(6)
      Column() {
        Row() {
          Text(this.fileName)
            .fontSize(14)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Text(this.fileDes)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      if (this.showCategory) {
        Text(this.timeCategory)
          .fontSize(11)
          .fontColor('#5B3CFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor('#F0EBFF')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => this.onClick())
  }
}

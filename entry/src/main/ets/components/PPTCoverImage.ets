@ComponentV2
export struct PPTCoverImage {
  @Param coverUrl: string = ''
  @Param borderRadius: number = 3

  build() {
    Image(this.coverUrl)
      .width('100%')
      .objectFit(ImageFit.Contain)
      .borderRadius(this.borderRadius)
  }
}

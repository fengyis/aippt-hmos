@ObservedV2 export class WebViewViewModel {
  @Trace url: string = ''
  @Trace title: string = ''
  @Trace isLoading: boolean = false
  load(url: string, title: string): void { this.url = url; this.title = title }
}

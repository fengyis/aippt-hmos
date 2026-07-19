import { AppTitleBar } from '../components/AppTitleBar'
import { PptTemplateCard } from '../components/PptTemplateCard'

@ObservedV2
class WorksState {
  @Trace tabType: number = 1
  @Trace isDeleteMode: boolean = false
  @Trace works: Object[] = []
  @Trace collects: Object[] = []
  @Trace isLoading: boolean = false
}
@Entry
@ComponentV2
struct WorksPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: WorksState = new WorksState()
  aboutToAppear(): void {
    // Works data loaded by WorksViewModel.findAll()
  }
  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: this.state.tabType === 1 ? '我的作品' : '我的收藏', showBack: true })
        Row() {
          Button('我的作品').fontColor(this.state.tabType === 1 ? '#5B3CFF' : '#999').backgroundColor(Color.Transparent)
            .onClick(() => { this.state.tabType = 1 })
          Button('我的收藏').fontColor(this.state.tabType === 2 ? '#5B3CFF' : '#999').backgroundColor(Color.Transparent)
            .onClick(() => { this.state.tabType = 2 })
        }.margin({ top: 12 })
        if (this.state.isLoading) { LoadingProgress().width(48).height(48).margin({ top: 100 }) }
        else { Text(this.state.tabType === 1 ? '我的作品空空如也' : '我的收藏空空如也').fontColor('#999').margin({ top: 60 }) }
      }.width('100%').height('100%').backgroundColor(Color.White)
    }.title('').hideTitleBar(true)
  }
}

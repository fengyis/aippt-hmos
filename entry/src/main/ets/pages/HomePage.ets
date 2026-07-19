import { promptAction } from '@kit.ArkUI'

@ObservedV2
class HomeState {
  @Trace currentTab: number = 0
  @Trace isExitConfirm: boolean = false
  @Trace showKeyboard: boolean = false
  @Trace showCampaignDialog: boolean = false
  @Trace showLimitedGiftDialog: boolean = false
}

@ComponentV2
struct HomeTabBar {
  @Param currentTab: number = 0
  @Event onTabChange: (index: number) => void = () => {}

  build() {
    Row() {
      this.TabItem(0, $r('sys.symbol.house'), '创作')
      this.TabItem(1, $r('sys.symbol.square_grid_2x2'), '模板')
      this.TabItem(2, $r('sys.symbol.folder'), '作品')
      this.TabItem(3, $r('sys.symbol.person'), '我的')
    }
    .width('100%')
    .height(56)
    .backgroundColor('#202022')
    .padding({ bottom: 8 })
  }

  @Builder
  TabItem(index: number, icon: Resource, label: string) {
    Column() {
      Column() {
        SymbolGlyph(icon)
          .fontSize(22)
          .fontColor(this.currentTab === index ? [Color.White] : ['#D1D5EB'])
      }
      .width(48).height(28).borderRadius(14)
      .backgroundColor(this.currentTab === index ? '#1F000000' : '#00000000')
      .justifyContent(FlexAlign.Center)

      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? Color.White : '#D1D5EB')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .onClick(() => this.onTabChange(index))
  }
}

@Entry
@ComponentV2
import { HomeViewModel } from '../viewmodel/HomeViewModel'

struct HomePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local homeState: HomeState = new HomeState()
  @Local homeVM: HomeViewModel = new HomeViewModel()
  private lastBackPress: number = 0

  aboutToAppear(): void {
    this.homeVM.initUser()
  }

  onBackPress(): boolean {
    const now = Date.now()
    if (now - this.lastBackPress < 2000) {
      return false
    }
    this.lastBackPress = now
    promptAction.showToast({ message: '再按一次退出程序' })
    return true
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        if (!this.homeState.showKeyboard) {
          if (this.homeState.currentTab === 0) {
            Text('创作 Tab')
              .width('100%').layoutWeight(1).textAlign(TextAlign.Center)
          } else if (this.homeState.currentTab === 1) {
            Text('模板 Tab')
              .width('100%').layoutWeight(1).textAlign(TextAlign.Center)
          } else if (this.homeState.currentTab === 2) {
            Text('作品 Tab')
              .width('100%').layoutWeight(1).textAlign(TextAlign.Center)
          } else {
            Text('我的 Tab')
              .width('100%').layoutWeight(1).textAlign(TextAlign.Center)
          }
        }

        if (!this.homeState.showKeyboard) {
          HomeTabBar({
            currentTab: this.homeState.currentTab,
            onTabChange: (index: number) => { this.homeState.currentTab = index }
          })
        }
      }
      .width('100%').height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }
}

import { AppTitleBar } from '../components/AppTitleBar'
import { UserDataModel, getUserData } from '../model/UserDataModel'

@ObservedV2
class MineState {
  @Trace isLoggedIn: boolean = false
  @Trace isVip: boolean = false
  @Trace nickname: string = ''
  @Trace avatar: string = ''
  @Trace vipContent: string = ''
  @Trace freeCount: number = 0
  @Trace cacheSize: string = '0KB'
  @Trace showServiceCenter: boolean = true
}

@Entry
@ComponentV2
struct MinePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: MineState = new MineState()
  @Local user: UserDataModel = getUserData()

  aboutToAppear(): void {
    this.state.isLoggedIn = this.user.isLogin()
    this.state.isVip = this.user.isVip()
    this.state.nickname = this.user.nickname
    this.state.freeCount = this.user.freeCount
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: '我的', showBack: true, onBackClick: () => this.navPathStack.pop() })

        Row() {
          if (this.state.isLoggedIn) {
            Column() {
              Image(this.state.avatar || $r('app.media.icon_app_logo'))
                .width(56).height(56).borderRadius(28)
              Text(this.state.nickname || '用户')
                .fontSize(16).fontWeight(FontWeight.Bold).margin({ top: 8 })
            }
            .onClick(() => this.navPathStack.pushPathByName('AccountInfoPage', undefined))
          } else {
            Column() {
              Image($r('app.media.icon_app_logo')).width(56).height(56).borderRadius(28)
              Text('点击登录').fontSize(16).fontColor('#5B3CFF').margin({ top: 8 })
            }
            .onClick(() => this.navPathStack.pushPathByName('LoginPage', undefined))
          }
        }
        .width('100%').padding(24).justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)

        if (!this.state.isVip) {
          Row() {
            Text('升级VIP · 尊享超多权益')
              .fontSize(14).fontColor('#E8A800').fontWeight(FontWeight.Bold)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#E8A800'])
          }
          .width('100%').padding(16).justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor('#FFF8E1')
          .margin({ left: 16, right: 16, top: 12 }).borderRadius(10)
          .onClick(() => this.navPathStack.pushPathByName('MemberCenterPage', undefined))
        }

        List() {
          if (this.state.showServiceCenter) {
            ListItem() { this.menuItem($r('sys.symbol.questionmark_circle'), '联系客服',
              () => this.navPathStack.pushPathByName('CustomerServiceWebPage', undefined)) }
          }
          ListItem() { this.menuItem($r('sys.symbol.gearshape'), '设置',
            () => { /* FWD-REF: P-S07-003 resolve_by=Slice 7 Step 3d */ }) }
          ListItem() { this.menuItem($r('sys.symbol.info_circle'), $r('app.string.str_about_us'),
            () => this.navPathStack.pushPathByName('AboutUsPage', undefined)) }
        }
        .width('100%').layoutWeight(1).margin({ top: 16 })
      }
      .width('100%').height('100%').backgroundColor('#F7F7F7')
    }
    .title('').hideTitleBar(true)
  }

  @Builder
  menuItem(icon: Resource, label: ResourceStr, action: () => void) {
    Row() {
      SymbolGlyph(icon).fontSize(20).fontColor(['#333333']).margin({ right: 12 })
      Text(label).fontSize(15).fontColor('#333333').layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor(['#CCCCCC'])
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .backgroundColor(Color.White).borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 8 })
    .onClick(action)
  }
}

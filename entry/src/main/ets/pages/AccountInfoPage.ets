import { promptAction } from '@kit.ArkUI'
import { AppTitleBar } from '../components/AppTitleBar'
import { UserDataModel, getUserData } from '../model/UserDataModel'

@Entry
@ComponentV2
struct AccountInfoPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local user: UserDataModel = getUserData()
  @Local showLogoutDialog: boolean = false
  @Local showDeleteDialog: boolean = false

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: $r('app.string.str_account_info'), showBack: true,
          onBackClick: () => this.navPathStack.pop() })

        Column() {
          Text($r('app.string.user_id_label'))
            .fontSize(12).fontColor('#999999')
          Text(this.user.userId)
            .fontSize(16).fontColor('#333333').margin({ top: 4 })

          Row() {
            Text($r('app.string.vip_level_label'))
              .fontSize(12).fontColor('#999999')
            Text(this.user.isVip() ? '高级会员' : '普通会员')
              .fontSize(14).fontColor(this.user.isVip() ? '#E8A800' : '#666666')
              .fontWeight(FontWeight.Bold)
              .margin({ left: 8 })
          }
          .margin({ top: 20 })

          if (this.user.isVip()) {
            Text(`${$r('app.string.vip_remaining_label')}: ${this.user.vipDayRemain}${$r('app.string.days')}`)
              .fontSize(12).fontColor('#999999').margin({ top: 8 })
          } else {
            Button($r('app.string.upgrade_vip'))
              .fontSize(14).fontColor(Color.White)
              .width(160).height(36).borderRadius(18)
              .backgroundColor('#5B3CFF')
              .margin({ top: 12 })
              .onClick(() => {
                this.navPathStack.pushPathByName('MemberCenterPage', undefined)
              })
          }
        }
        .width('100%')
        .padding(20)
        .margin({ top: 20, left: 16, right: 16 })
        .borderRadius(12)
        .backgroundColor('#FAFAFA')
        .alignItems(HorizontalAlign.Center)

        Divider().margin({ top: 32, left: 16, right: 16 }).color('#E0E0E0')

        List() {
          ListItem() {
            Row() {
              Text($r('app.string.str_login_out'))
                .fontSize(16).fontColor('#E84026')
            }
            .width('100%').height(48).padding({ left: 16 })
            .onClick(() => { this.showLogoutDialog = true })
          }
          ListItem() {
            Row() {
              Text($r('app.string.str_delete_account'))
                .fontSize(16).fontColor('#E84026')
            }
            .width('100%').height(48).padding({ left: 16 })
            .onClick(() => { this.showDeleteDialog = true })
          }
        }
        .width('100%')
        .margin({ top: 16 })
        .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('')
    .hideTitleBar(true)
  }
}

import { SplashPage } from './SplashPage'
import { HomePage } from './HomePage'
import { LoginPage } from './LoginPage'
import { AccountInfoPage } from './AccountInfoPage'
import { MemberCenterPage } from './MemberCenterPage'
import { CreateOutLinePage } from './CreateOutLinePage'
import { ChoicePPTTemplatePage } from './ChoicePPTTemplatePage'
import { PPTTemplatePreviewPage } from './PPTTemplatePreviewPage'
import { PPTFilePage } from './PPTFilePage'
import { SearchPage } from './SearchPage'
import { FileUploadPage } from './FileUploadPage'
import { FileListPage } from './FileListPage'
import { WorksPage } from './WorksPage'
import { MinePage } from './MinePage'
import { WebViewPage } from './WebViewPage'
import { CustomerServiceWebPage } from './CustomerServiceWebPage'
import { ManageRenewPage } from './ManageRenewPage'
import { RefundProgressPage } from './RefundProgressPage'
import { GuidePage } from './GuidePage'
import { AboutUsPage } from './AboutUsPage'
import { ShortCutPage } from './ShortCutPage'

@Entry
@ComponentV2
struct Index {
  @Provider('navPathStack') navPathStack: NavPathStack = new NavPathStack()

  @Builder
  PageMap(name: string) {
    if (name === 'SplashPage') { SplashPage() }
    else if (name === 'HomePage') { HomePage() }
    else if (name === 'LoginPage') { LoginPage() }
    else if (name === 'AccountInfoPage') { AccountInfoPage() }
    else if (name === 'MemberCenterPage') { MemberCenterPage() }
    else if (name === 'CreateOutLinePage') { CreateOutLinePage() }
    else if (name === 'ChoicePPTTemplatePage') { ChoicePPTTemplatePage() }
    else if (name === 'PPTTemplatePreviewPage') { PPTTemplatePreviewPage() }
    else if (name === 'PPTFilePage') { PPTFilePage() }
    else if (name === 'SearchPage') { SearchPage() }
    else if (name === 'FileUploadPage') { FileUploadPage() }
    else if (name === 'FileListPage') { FileListPage() }
    else if (name === 'WorksPage') { WorksPage() }
    else if (name === 'MinePage') { MinePage() }
    else if (name === 'WebViewPage') { WebViewPage() }
    else if (name === 'CustomerServiceWebPage') { CustomerServiceWebPage() }
    else if (name === 'ManageRenewPage') { ManageRenewPage() }
    else if (name === 'RefundProgressPage') { RefundProgressPage() }
    else if (name === 'GuidePage') { GuidePage() }
    else if (name === 'AboutUsPage') { AboutUsPage() }
    else if (name === 'ShortCutPage') { ShortCutPage() }
  }

  aboutToAppear(): void {
    this.navPathStack.pushPathByName('SplashPage', undefined)
  }

  build() {
    Navigation(this.navPathStack) {
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
  }
}

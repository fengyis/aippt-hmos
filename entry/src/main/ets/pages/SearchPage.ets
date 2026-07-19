import { AppTitleBar } from '../components/AppTitleBar'
import { PptTemplateCard } from '../components/PptTemplateCard'
@ObservedV2 class SearchState { @Trace keyword: string = ''; @Trace templates: Object[] = [] }
@Entry @ComponentV2 struct SearchPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: SearchState = new SearchState()
  aboutToAppear(): void { /* FWD-REF: P-S04-006 resolve_by=Slice 4 Step 3c — fetchTemplates */ }
  build() {
    NavDestination() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => this.navPathStack.pop())
          TextInput({ placeholder: '请输入模版名称', text: this.state.keyword })
            .layoutWeight(1).height(38).backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#E8E8E8' }).borderRadius(20)
            .onChange((v: string) => { this.state.keyword = v })
        }.padding({ left: 16, right: 16 })
        Grid() {
          ForEach(this.state.templates, (t: Object) => { GridItem() { PptTemplateCard({ coverUrl: '', templateName: '' }) } })
        }.columnsTemplate('1fr 1fr').columnsGap(12).rowsGap(12).layoutWeight(1).padding(16)
      }.width('100%').height('100%').backgroundColor(Color.White)
    }.title('').hideTitleBar(true)
  }
}

import { AppTitleBar } from '../components/AppTitleBar'
import { StepIndicator, StepData } from '../components/StepIndicator'
import { PptTemplateCard } from '../components/PptTemplateCard'
import { PptViewModel } from '../viewmodel/PptViewModel'

@ObservedV2
class ChoiceState {
  @Trace categories: string[] = []
  @Trace currentCategory: number = 0
  @Trace templates: Object[] = []
  @Trace isLoading: boolean = false
}

@Entry
@ComponentV2
struct ChoicePPTTemplatePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: ChoiceState = new ChoiceState()

  aboutToAppear(): void {
    // Template list loaded by PptViewModel.fetchTemplateList()
    this.state.categories = ['推荐', '工作总结', '商业计划', '教育培训', '营销策划', '毕业论文']
  }

  onTemplateClick(template: Object): void {
    this.navPathStack.pushPathByName('PPTTemplatePreviewPage', template)
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({
          title: this.state.isLoading ? '精品模版' : '请选择模版',
          showBack: true,
          showRightIcon: true,
          rightIconSymbol: $r('sys.symbol.magnifyingglass'),
          onBackClick: () => this.navPathStack.pop(),
          onRightClick: () => this.navPathStack.pushPathByName('SearchPage', undefined)
        })

        StepIndicator({
          steps: [new StepData('1', '输入主题'), new StepData('2', '生成大纲'),
            new StepData('3', '选择模版'), new StepData('4', '生成PPT')],
          currentStep: 2
        })

        Tabs({ barPosition: BarPosition.Start, index: this.state.currentCategory }) {
          ForEach(this.state.categories, (cat: string, index: number) => {
            TabContent() {
              Grid() {
                ForEach(this.state.templates, (t: Object) => {
                  GridItem() {
                    PptTemplateCard({
                      coverUrl: (t as Record<string,string>)['coverUrl'] ?? '',
                      templateName: (t as Record<string,string>)['templateName'] ?? '',
                      onClick: () => this.onTemplateClick(t)
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(10).rowsGap(10)
              .padding(12)
            }
            .tabBar(cat)
          })
        }
        .barMode(BarMode.Scrollable)
        .layoutWeight(1)
        .onChange((index: number) => { this.state.currentCategory = index })
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}

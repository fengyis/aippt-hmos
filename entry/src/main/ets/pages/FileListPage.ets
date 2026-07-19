import { AppTitleBar } from '../components/AppTitleBar'
import { FileListItem } from '../components/FileListItem'
import { ScanFileBean } from '../model/ScanFileBean'

@ObservedV2
class FileListState {
  @Trace files: ScanFileBean[] = []
  @Trace isLoading: boolean = false
  @Trace searchKeyword: string = ''
}

@Entry
@ComponentV2
struct FileListPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: FileListState = new FileListState()

  aboutToAppear(): void {
    this.scanFiles()
  }

  scanFiles(): void {
    this.state.isLoading = true
    // FWD-REF: P-S05-001 resolve_by=Slice 5 Step 3c — FileScanRepository.scanAll()
    this.state.isLoading = false
  }

  onSearch(keyword: string): void {
    this.state.searchKeyword = keyword
    // FWD-REF: P-S05-002 resolve_by=Slice 5 Step 3c — FileScanRepository.search(keyword)
  }

  onFileClick(file: ScanFileBean): void {
    // FWD-REF: P-S05-003 resolve_by=Slice 5 Step 3d — FileConfirmDialog → CreateOutLinePage(filePath, FROM_FILE_IMPORT)
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(22).fontColor(['#333333'])
            .onClick(() => this.navPathStack.pop())

          TextInput({ placeholder: '请输入文件名称', text: this.state.searchKeyword })
            .layoutWeight(1).height(38)
            .backgroundColor('#F7F7F7').borderRadius(20)
            .margin({ left: 12, right: 12 })
            .onChange((value: string) => this.onSearch(value))
        }
        .width('100%').padding({ left: 16, right: 16, top: 8 })

        if (this.state.isLoading) {
          LoadingProgress().width(48).height(48).margin({ top: 100 })
        } else {
          List() {
            ForEach(this.state.files, (file: ScanFileBean) => {
              ListItem() {
                FileListItem({
                  fileName: file.fileName,
                  fileDes: file.fileDes,
                  timeCategory: file.timeCategory,
                  showCategory: file.showCategory,
                  keyword: this.state.searchKeyword,
                  onClick: () => this.onFileClick(file)
                })
              }
            })
          }
          .layoutWeight(1).margin({ top: 12 })
          .scrollBar(BarState.Off)
          .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
        }
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}

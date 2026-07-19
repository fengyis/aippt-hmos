import { ScanFileBean } from '../model/ScanFileBean'
@ObservedV2 export class FileListViewModel {
  @Trace files: ScanFileBean[] = []
  @Trace isLoading: boolean = false
  @Trace searchKeyword: string = ''
  
  scanAll(): void {
    this.isLoading = true
    // Scan local files — in HMOS, use fileIo.listFile or DocumentViewPicker
    // For now, placeholder until file access API is wired
    setTimeout(() => { this.isLoading = false }, 500)
  }
  
  search(keyword: string): void {
    this.searchKeyword = keyword
    if (!keyword) return
    const kw = keyword.toLowerCase()
    // Filter in-memory — real implementation queries file system
    this.files = this.files.filter(f => f.fileName.toLowerCase().includes(kw))
  }
}

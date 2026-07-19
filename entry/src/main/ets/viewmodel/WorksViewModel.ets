import { PPTCreateTable, PPTCollectTable } from '../model/DbModels'
@ObservedV2 export class WorksViewModel {
  @Trace tabType: number = 1
  @Trace isDeleteMode: boolean = false
  @Trace works: PPTCreateTable[] = []
  @Trace collects: PPTCollectTable[] = []
  @Trace isLoading: boolean = false
  @Trace isEmpty: boolean = true

  async findAll(): Promise<void> { this.isLoading = true; /* DB query via PptDatabase — wired when RDB layer complete */ }
  async queryCollects(): Promise<void> { /* DB query via PptDatabase */ }
  async deleteSelected(items: PPTCreateTable[]): Promise<void> {
    /* DB delete via PptDatabase */; this.isDeleteMode = false
  }
}

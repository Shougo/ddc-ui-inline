import { Context, DdcItem } from "https://deno.land/x/ddc_vim@v3.2.0/types.ts";
import { BaseUi } from "https://deno.land/x/ddc_vim@v3.2.0/base/ui.ts";
import { Denops } from "https://deno.land/x/ddc_vim@v3.2.0/deps.ts";

export type Params = {
  highlight: string;
};

export class Ui extends BaseUi<Params> {
  override async show(args: {
    denops: Denops;
    context: Context;
    completePos: number;
    items: DdcItem[];
    uiParams: Params;
  }): Promise<void> {
    await args.denops.call(
      "ddc#ui#inline#_show",
      args.completePos,
      args.items,
      args.uiParams.highlight,
    );
  }

  override async hide(args: {
    denops: Denops;
  }): Promise<void> {
    await args.denops.call("ddc#ui#inline#_hide");
  }

  override params(): Params {
    return {
      highlight: "Comment",
    };
  }
}

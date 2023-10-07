import { Context, DdcItem } from "https://deno.land/x/ddc_vim@v4.0.5/types.ts";
import { BaseUi } from "https://deno.land/x/ddc_vim@v4.0.5/base/ui.ts";
import { Denops, fn } from "https://deno.land/x/ddc_vim@v4.0.5/deps.ts";

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

  override async skipCompletion(args: {
    denops: Denops;
  }): Promise<boolean> {
    // Skip for other popup
    const checkNative = await fn.pumvisible(args.denops) !== 0;
    const checkPum = await fn.exists(args.denops, "pum#visible") &&
      await args.denops.call("pum#visible") as boolean;
    return checkNative || checkPum;
  }

  override async hide(args: {
    denops: Denops;
  }): Promise<void> {
    await args.denops.call("ddc#ui#inline#_hide");
  }

  override async visible(args: {
    denops: Denops;
  }): Promise<boolean> {
    return await args.denops.call("ddc#ui#inline#visible") as boolean;
  }

  override params(): Params {
    return {
      highlight: "Comment",
    };
  }
}

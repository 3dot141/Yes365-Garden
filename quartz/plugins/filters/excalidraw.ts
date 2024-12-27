import { QuartzFilterPlugin } from "../types"

export const RemoveExcalidraws: QuartzFilterPlugin<{}> = () => ({
  name: "RemoveExcalidraws",
  shouldPublish(_ctx, [_tree, vfile]) {
    const excalidraw: boolean = !vfile.data?.frontmatter?.tags?.includes("excalidraw")
    return excalidraw!
  },
})

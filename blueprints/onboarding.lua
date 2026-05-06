-- Personal Win11 onboarding blueprint.
--
-- Stacks on top of the foundation layers (currently embedded; will migrate to
-- main/<bp> once a main bp source repo exists per DESIGN §9.10 议题 AG).

return {
  schema = 1,
  name = "onboarding",
  description = "Personal Win11 onboarding (luban v1.0 transition)",
  tools = {},
  configs = {},
  meta = {
    requires = {
      "main/git-base",
      "main/cpp-base",
      "main/cli-base",
    },
    conflicts = {},
  },
  -- TODO: pwsh / wt / Maple Mono — pending pwsh.lua + wt.lua renderers
  -- and font_deploy capability (separate work items per plan).
}

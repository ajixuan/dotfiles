return  {
  {
    "folke/which-key.nvim",
    -- Press a starting key and wait, and it will have a popup show up with the key maps available
    -- This does not work with ctrl however
    event = "VeryLazy",

    opts = {
       triggers = {
         { "<auto>", mode = "nixsoc" },
       }
    }
  }
}

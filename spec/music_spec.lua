require 'busted.runner' ()

describe("a test", function()
    local input =
    [[HEART BEAT\tYOASOBI, Love You Tender! (TV Size Ver.)\tMaaya Uchida, 向かい風に打たれながら\tMinori Chihara, STEP by STEP UP↑↑↑↑\tfourfolium
    ]]
    input = input:gsub("\\t", "\t")
    local output = {
        { "HEART BEAT", "YOASOBI" },
        { "Love You Tender! (TV Size Ver.)", "Maaya Uchida" },
        { "向かい風に打たれながら", "Minori Chihara" },
        { "STEP by STEP UP↑↑↑↑", "fourfolium" },
    }

    it("turn_string_into_table", function()
        local music = require('music')
        assert.are.same(output, music.make_music_to_list(input))
    end)
end)

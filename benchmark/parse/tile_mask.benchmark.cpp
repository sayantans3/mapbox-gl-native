#include <benchmark/benchmark.h>

#include <mbgl/algorithm/update_tile_masks.hpp>

using namespace mbgl;

struct MaskedRenderable {
    UnwrappedTileID id;
    TileMask mask;
    bool used = true;

    void setMask(TileMask&& mask_) {
        mask = std::move(mask_);
    }
};

static void TileMaskGeneration(benchmark::State& state) {
    std::vector<MaskedRenderable> renderables = {
        MaskedRenderable{ UnwrappedTileID{ 12, 1028, 1456 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 13, 2056, 2912 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 13, 2056, 2913 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 14, 4112, 5824 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 14, 4112, 5827 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 14, 4114, 5824 }, TileMask{} },
        MaskedRenderable{ UnwrappedTileID{ 14, 4114, 5825 }, TileMask{} },
    };

    while (state.KeepRunning()) {
        algorithm::updateTileMasks<MaskedRenderable>({ renderables.begin(), renderables.end() });
    }
}

BENCHMARK(TileMaskGeneration);

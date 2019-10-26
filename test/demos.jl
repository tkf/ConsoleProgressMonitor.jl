# Juno.progress
function progress(f; name = "")
    _id = gensym()
    @info name progress=0.0 _id=_id
    try
        f(_id)
    finally
        @info name progress="done" _id=_id
    end
end

function demo1()
    progress(name="outer") do id
        for i in 1:10
            sleep(1e-3)
            @info "outer" progress=i/10
        end
    end
end

function demo2()
    progress(name="outer") do id
        for i in 1:10
            progress(name="inner") do id
                for j in 1:10
                    sleep(1e-3)
                    @info "inner" progress=i/10
                end
            end
            @info "outer" progress=i/10
        end
    end
end

module ProgressMeterLogging

import Logging
using ProgressMeter: Progress, finish!, update!

"""
    ProgressLogger(; progress_options...)
"""
struct ProgressLogger <: Logging.AbstractLogger
    options::NamedTuple
    bars::Dict{Symbol, Progress}
    lastid::typeof(Ref(:_))
end

const _noid = gensym(:_noid)

ProgressLogger(options::NamedTuple) = ProgressLogger(options, Dict(), Ref(_noid))
ProgressLogger(; options...) = ProgressLogger((; options...))

# https://docs.julialang.org/en/latest/stdlib/Logging/#AbstractLogger-interface-1

likelytoprint(p) = time() + 1e-3 - p.tlast > p.dt

function Logging.handle_message(
    logger::ProgressLogger,
    level, title, _module, group, id, file, line;
    progress = nothing,
    message = nothing,
    _...
)
    n = 1000
    if progress isa Real && (progress <= 1 || isnan(progress))
        p = get!(logger.bars, id) do
            desc = something(title, message, "Progress: ")
            if !endswith(desc, " ")
                desc = string(desc, ": ")
            end
            Progress(n; desc=desc, logger.options...)
        end
        progress = isnan(progress) ? 0.0 : progress
        counter = floor(Int, progress * n)
        if logger.lastid[] ∉ (id, _noid) && likelytoprint(p)
            # Switched from unfinished progress bar:
            println(p.output)
        end
        update!(p, counter)
        if p.printed
            logger.lastid[] = id
        end
    elseif progress == "done" || (progress isa Real && progress > 1)
        p = pop!(logger.bars, id, nothing)
        p === nothing && return
        finish!(p)
        logger.lastid[] = _noid
    end
    return
end

Logging.shouldlog(::ProgressLogger, level, _module, group, id) =
    true

Logging.min_enabled_level(::ProgressLogger) = Logging.BelowMinLevel

"""
    install_logger([logger])

Install `ProgressLogger` using `LoggingExtras.DemuxLogger`.
"""
install_logger(; options...) = install_logger(ProgressLogger(; options...))

function install_logger(logger::ProgressLogger)
    global previous_logger
    pkgid = Base.PkgId(
        Base.UUID("e6f89c97-d47a-5376-807f-9c37f3926c36"),
        "LoggingExtras",
    )
    LoggingExtras = Base.require(pkgid)
    previous_logger = Base.invokelatest() do
        Logging.global_logger(LoggingExtras.DemuxLogger(logger))
    end
end

"""
    uninstall_logger()

Rollback the global logger to the one before last call of `install_logger`.
"""
function uninstall_logger()
    global previous_logger
    previous_logger === nothing && return
    ans = Logging.global_logger(previous_logger)
    previous_logger = nothing
    return ans
end

end # module

module ConsoleProgressMonitor

# Use README as the docstring of the module:
@doc read(joinpath(dirname(@__DIR__), "README.md"), String) ConsoleProgressMonitor

import Logging
import LoggingExtras
using ProgressMeter: Progress, finish!, update!

const default_colors = [
    :green, :blue, :magenta, :cyan, :yellow, :red, :light_black,
    :light_green, :light_blue, :light_magenta, :light_cyan,
    :light_yellow, :light_red,
]

"""
    ProgressLogger(; colors, progress_options...)

# Keyword Arguments
- `colors :: Vector{Symbol}`: a list of colors used for progress meters.
- Other keyword arguments are used for constructing `ProgressMeter.Progress`.
"""
struct ProgressLogger <: Logging.AbstractLogger
    options::NamedTuple
    colors::Vector{Symbol}
    bars::Dict{Symbol, Progress}
    lastid::typeof(Ref(:_))
end

const _noid = gensym(:_noid)

ProgressLogger(options::NamedTuple, colors::Vector{Symbol} = default_colors) =
    ProgressLogger(options, colors, Dict(), Ref(_noid))
ProgressLogger(; colors=default_colors, options...) =
    ProgressLogger((; options...), colors)

# https://docs.julialang.org/en/latest/stdlib/Logging/#AbstractLogger-interface-1

likelytoprint(p) = time() + 1e-3 - p.tlast > p.dt

pickcycle(xs, i) = xs[mod1(i, length(xs))]

somestring(x) = x
somestring(x, xs...) =
    x isa AbstractString && !isempty(x) ? x : somestring(xs...)

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
            color = pickcycle(logger.colors, length(logger.bars) + 1)
            Progress(n; color=color, logger.options...)
        end

        progress = isnan(progress) ? 0.0 : progress
        counter = floor(Int, progress * n)

        desc = somestring(title, message, p.desc)
        if !endswith(desc, " ")
            desc = string(desc, ": ")
        end
        p.desc = desc

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
    with_progresslogger(f; options...)

Run `f` with `ProgressLogger` enabled.
"""
with_progresslogger(f; options...) =
    Logging.with_logger(f, ProgressLogger(; options...))

"""
    install_logger(; options...)
    install_logger(logger::ProgressLogger)

Install `ProgressLogger` using `LoggingExtras.DemuxLogger`.

Keyword arguments `options` are passed to `ProgressLogger` constructor.
"""
install_logger(; options...) = install_logger(ProgressLogger(; options...))

function install_logger(logger::ProgressLogger)
    global previous_logger
    #=
    pkgid = Base.PkgId(
        Base.UUID("e6f89c97-d47a-5376-807f-9c37f3926c36"),
        "LoggingExtras",
    )
    LoggingExtras = Base.require(pkgid)
    previous_logger = Base.invokelatest() do
        Logging.global_logger(LoggingExtras.DemuxLogger(logger))
    end
    =#
    previous_logger = Logging.global_logger(LoggingExtras.DemuxLogger(logger))
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

using Logging: Logging, AbstractLogger

struct ProgressLogRouter{D<:AbstractLogger,P<:AbstractLogger} <: AbstractLogger
    defaultlogger::D
    progresslogger::P
end

_hasprogress(; progress = nothing, _...) = progress === "done" || progress isa Real

function Logging.handle_message(logger::ProgressLogRouter, args...; kwargs...)
    level, _, _module, group, id = args
    if _hasprogress(; kwargs...)
        Logging.handle_message(logger.progresslogger, args...; kwargs...)
    elseif level >= Logging.min_enabled_level(logger) &&
           Logging.shouldlog(logger, level, _module, group, id)
        Logging.handle_message(logger.defaultlogger, args...; kwargs...)
    end
end

Logging.shouldlog(logger::ProgressLogRouter, args...) =
    Logging.shouldlog(logger.defaultlogger, args...) ||
    Logging.shouldlog(logger.progresslogger, args...)

Logging.min_enabled_level(logger::ProgressLogRouter) = min(
    Logging.min_enabled_level(logger.defaultlogger),
    Logging.min_enabled_level(logger.progresslogger),
)

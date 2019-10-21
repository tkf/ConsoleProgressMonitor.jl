module TestConsoleProgressMonitor

using ConsoleProgressMonitor
using Logging
using Test

include("demos.jl")

@testset "with_progresslogger" begin
    @test ConsoleProgressMonitor.with_progresslogger(demo1, dt=0) isa Any
    @test ConsoleProgressMonitor.with_progresslogger(demo2, dt=0) isa Any
end

@testset "(un)install_logger" begin
    if get(ENV, "CI", "false") == "true"
        orig = global_logger()
        @test ConsoleProgressMonitor.install_logger() === orig
        @test global_logger() !== orig
        demo1()
        demo2()
        @test ConsoleProgressMonitor.uninstall_logger() isa AbstractLogger
        @test global_logger() === orig
    end
end

end  # module

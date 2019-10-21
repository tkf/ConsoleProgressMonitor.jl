# ConsoleProgressMonitor.jl: A ProgressMeter.jl-Logging.jl bridge

[![Build Status](https://travis-ci.com/tkf/ConsoleProgressMonitor.jl.svg?branch=master)](https://travis-ci.com/tkf/ConsoleProgressMonitor.jl)
[![Codecov](https://codecov.io/gh/tkf/ConsoleProgressMonitor.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/ConsoleProgressMonitor.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/ConsoleProgressMonitor.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/ConsoleProgressMonitor.jl?branch=master)

## Usage

### Setup

```julia
julia> using ConsoleProgressMonitor

julia> ConsoleProgressMonitor.install_logger();
```

Alternatively, use `ConsoleProgressMonitor.with_progresslogger` to
temporary enable `ConsoleProgressMonitor`.

### Print progress meter

Any logging events that are compatible with
[`Juno.progress`](http://docs.junolab.org/latest/man/juno_frontend/#Progress-Meters-1)
specification are displayed using `ProgressMeter.Progress`.

```julia
julia> let id = gensym(:id)
           for i = 1:10
               sleep(0.1)
               @debug "iterating" progress=i/10 _id=id
           end
           @debug "iterating" progress="done" _id=id
       end
```

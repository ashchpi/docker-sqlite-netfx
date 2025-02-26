FROM gcc:14 AS build
COPY sqlite-netfx-source /usr/src/sqlite-netfx
WORKDIR /usr/src/sqlite-netfx/SQLite.Interop/src/generic/
RUN gcc -g -fPIC -shared -march=native -o libSQLite.Interop.so interop.c -I../core -DSQLITE_THREADSAFE=1 -DSQLITE_USE_URI=1 -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_ENABLE_STAT4=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_LOAD_EXTENSION=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_SOUNDEX=1 -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 -DSQLITE_ENABLE_API_ARMOR=1 -DSQLITE_ENABLE_DBSTAT_VTAB=1 -DSQLITE_ENABLE_STMTVTAB=1 -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1 -DINTEROP_TEST_EXTENSION=1 -DINTEROP_EXTENSION_FUNCTIONS=1 -DINTEROP_VIRTUAL_TABLE=1 -DINTEROP_FTS5_EXTENSION=1 -DINTEROP_PERCENTILE_EXTENSION=1 -DINTEROP_TOTYPE_EXTENSION=1 -DINTEROP_REGEXP_EXTENSION=1 -DINTEROP_JSON1_EXTENSION=1 -DINTEROP_SHA1_EXTENSION=1 -DINTEROP_SHA3_EXTENSION=1 -DINTEROP_SESSION_EXTENSION=1 -lm -lpthread -ldl
RUN cp libSQLite.Interop.so /usr/src/

FROM mcr.microsoft.com/dotnet/sdk:3.1 AS netbuild
COPY sqlite-netfx-source /usr/src/sqlite-netfx
WORKDIR /usr/src/sqlite-netfx/Setup
RUN bash build-netstandard21-release.sh
RUN cp /usr/src/sqlite-netfx/bin/NetStandard21/ReleaseNetStandard21/bin/netstandard2.1/System.Data.SQLite.dll /usr/src/
RUN cp /usr/src/sqlite-netfx/bin/NetStandard21/ReleaseNetStandard21/bin/netstandard2.1/System.Data.SQLite.EF6.dll /usr/src/

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /usr/lib
COPY --from=build /usr/src/libSQLite.Interop.so .
COPY --from=netbuild /usr/src/System.Data.SQLite.dll .
COPY --from=netbuild /usr/src/System.Data.SQLite.EF6.dll .
RUN ln -s /usr/lib/libSQLite.Interop.so /usr/lib/SQLite.Interop.dll

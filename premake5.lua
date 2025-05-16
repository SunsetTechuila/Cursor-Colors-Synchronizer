workspace "CursorColorsSynchronizer"
    platforms { "x86", "x64" }
    configurations { "Debug", "Release" }
    startproject "CursorColorsSynchronizer"
    systemversion "latest"
    postbuildcommands { "{COPY} %{wks.location}/src/Resources %{cfg.targetdir}/Resources" }

outputdir = "%{cfg.buildcfg}-%{cfg.architecture}"

-- Common configurations for all projects
function SetCommonProjectSettings()
    language "C++"
    cppdialect "C++20"
    staticruntime "on"
    defines { "PLATFORM_WINDOWS" }
    includedirs { "src" }

    filter "configurations:Debug"
        defines { "DEBUG" }
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        defines { "NDEBUG" }
        runtime "Release"
        optimize "on"
end

-- Main application project
project "CursorColorsSynchronizer"
    kind "ConsoleApp"
    SetCommonProjectSettings()

    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

    files
    {
        "src/**.hpp",
        "src/**.cpp"
    }

    removefiles { "src/Listener/**.hpp", "src/Listener/**.cpp" }

-- BackgroundListener project
-- Not fully implemented yet
-- project "BackgroundListener"
--     kind "ConsoleApp"
--     SetCommonProjectSettings()

--     targetdir ("bin/" .. outputdir .. "/%{prj.name}")
--     objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

--     files
--     {
--         "src/Core/**.hpp",
--         "src/Core/**.cpp",
--         "src/Listener/**.hpp",
--         "src/Listener/**.cpp"
--     }

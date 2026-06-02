# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(arena LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "arena")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Le SDK Firebase C++ (téléchargé par firebase_core pour Windows) déclare
# `cmake_minimum_required(VERSION <3.5)` — incompatible avec CMake 4.x
# (VS 2026) qui a retiré la compatibilité < 3.5. Sans ce minimum de
# politique, le configure échoue : « Unable to generate build files ».
# Sans effet sur les CMake plus anciens (variable simplement ignorée).
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# ─── Registrant filtré (plugins mobile-only exclus) ───────────────────
# `generated_plugin_registrant.cc` (régénéré par Flutter à chaque build)
# inclut et enregistre firebase_core, que l'on exclut du build Windows
# (cf. ARENA_WINDOWS_EXCLUDED_PLUGINS plus bas). On produit une copie
# filtrée dans le dossier de build et c'est elle que le runner compile.
file(READ "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  _arena_registrant)
# Le header relatif doit rester résoluble depuis le dossier de build.
string(REPLACE "#include \"generated_plugin_registrant.h\""
  "#include \"${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.h\""
  _arena_registrant "${_arena_registrant}")
# Retire l'include et l'appel d'enregistrement de firebase_core.
string(REGEX REPLACE "#include <firebase_core/[^\n]*\n" ""
  _arena_registrant "${_arena_registrant}")
string(REGEX REPLACE "  FirebaseCorePluginCApi[^;]*;\n" ""
  _arena_registrant "${_arena_registrant}")
set(ARENA_PLUGIN_REGISTRANT
  "${CMAKE_CURRENT_BINARY_DIR}/arena_filtered_plugin_registrant.cc")
file(WRITE "${ARENA_PLUGIN_REGISTRANT}" "${_arena_registrant}")

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
#
# ─── Exclusion des plugins mobile-only ────────────────────────────────
# Certains packages du pubspec déclarent un support Windows mais ne sont
# JAMAIS utilisés par l'app desktop (lib/main_admin_desktop.dart) et
# cassent ou alourdissent le build natif :
#   * firebase_core : télécharge + compile le SDK Firebase C++ (NuGet,
#     CMakeLists ancien) — FCM n'existe pas sur Windows, le bootstrap
#     desktop n'initialise jamais Firebase.
#   * jni : interop Java (dépendance transitive Android-only) — exige un
#     JDK (FindJNI) pour compiler son stub natif Windows.
# On lit generated_plugins.cmake (régénéré par Flutter à chaque build),
# on retire ces plugins des listes, puis on exécute le résultat. Le
# filtre survit donc à la régénération du fichier.
set(ARENA_WINDOWS_EXCLUDED_PLUGINS
  firebase_core
  jni
)
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/flutter/generated_plugins.cmake"
  _arena_plugins_content)
foreach(_excluded ${ARENA_WINDOWS_EXCLUDED_PLUGINS})
  string(REGEX REPLACE "[ \t]+${_excluded}\n" ""
    _arena_plugins_content "${_arena_plugins_content}")
endforeach()
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/arena_filtered_plugins.cmake"
  "${_arena_plugins_content}")
include("${CMAKE_CURRENT_BINARY_DIR}/arena_filtered_plugins.cmake")


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

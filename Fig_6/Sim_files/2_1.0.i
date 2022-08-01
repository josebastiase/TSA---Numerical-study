# this is a steady state simulation of Wang and Hsieh simulation of Earth tides in
# a confined aquifer. For more read wang_no_leakage_ss.i

# A free drainage BC is used to simulate the flux to the well. At the end of
# every time step the water in the well is computed as pressure and applied as BC
# to the next time step. Such approach rises dificulties to converge when long time steps
# and high permeability is set. Hence, max_dt is set.

[Mesh]
  [file]
    type = FileMeshGenerator
    file = gold/wang_ss.e
    use_for_exodus_restart = true
  []
[]

[Problem]
  coord_type = RZ
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  PorousFlowDictator = dictator
  multiply_by_density = true
  biot_coefficient = 1.0
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [porepressure]
    initial_from_file_var = porepressure
    #scaling = 1E-9
  []
  [h]
    family = SCALAR
    order = FIRST
    initial_condition = 1.0102319181064e+02
  []
[]

[ScalarKernels]
  [td]
    type = ODETimeDerivative
    variable = h
  []
  [water_level]
    type = ParsedODEKernel
    function = '(-flux) *1E-3 * injection_area / 0.12566' # m/s  -flux (kg/s/m2) * area / density / (area of the cylinder pi*r**2)
    variable = h
    postprocessors = 'flux injection_area'
  []
[]

[AuxVariables]
  [fluxes]
  []
  [wellPP]
  []
  [stress_rr]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_tt]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_ver]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [stress_rr]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_rr
    index_i = 0
    index_j = 0
  []
  [stress_tt]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_tt
    index_i = 2
    index_j = 2
  []
  [stress_ver]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_ver
    index_i = 1
    index_j = 1
  []
  [wellPP]
    type = FunctionAux
    function = wellPP
    variable = wellPP
  []
[]

[UserObjects]
  [steady_state_solution]
    type = SolutionUserObject
    execute_on = INITIAL
    mesh = gold/wang_ss.e
    timestep = LATEST
    system_variables = 'stress_rr stress_tt stress_ver'
  []
[]

[Functions]
  [tide]
    type = ParsedFunction
    value = '1E-8*sin((t)*4*pi/24/3600) * 101'
  []
  [wellPP] # pp in the well for post
    type = ParsedFunction
    value = '(h - (101 + y)) * 1E4'
    vars = 'h'
    vals = 'h'
  []
  [tidal_head] # Theoretical generated confined pp by the tide i.e. tide/Ss
    type = ParsedFunction
    value = '1E-8*sin((t)*4*pi/24/3600)'
  []
  [steady_state_rr]
    type = SolutionFunction
    from_variable = stress_rr
    solution = steady_state_solution
  []
  [steady_state_ver]
    type = SolutionFunction
    from_variable = stress_ver
    solution = steady_state_solution
  []
  [steady_state_tt]
    type = SolutionFunction
    from_variable = stress_tt
    solution = steady_state_solution
  []
  [inject]
    type = ParsedFunction
    value = 'if(t > 0, 1, 0)'
  []
[]

[BCs]
  [out_right]
    type = PorousFlowPiecewiseLinearSink
    variable = porepressure
    boundary = 'injection_area'
    pt_vals = '-1.2e6 1.2e6'
    multipliers = '-1.2e6 1.2e6'
    PT_shift = wellPP
    flux_function = 0.01 # This value changes with permeability
    fluid_phase = 0
    save_in = fluxes
  []
  [no_x_disp]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left_no_flux injection_area right'
  []
  [no_y_disp]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'top'
  []
  [disp_y_bottom]
    type = FunctionDirichletBC
    variable = disp_y
    function = tide
    boundary = 'bottom'
  []
  [pp]
    type = FunctionDirichletBC
    variable = porepressure
    function = 0
    boundary = top
  []
[]

[Modules]
  [FluidProperties]
    [the_simple_fluid]
      type = SimpleFluidProperties
      thermal_expansion = 0.0
      bulk_modulus = 2.2E9
      viscosity = 1E-3
      density0 = 1000.0
    []
  []
[]

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y'
  porepressure = porepressure
  gravity = '0 -10 0'
  fp = the_simple_fluid
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 1E10 # drained bulk modulus
    poissons_ratio = 0.25
  []
  [strain]
    type = ComputeAxisymmetricRZSmallStrain
    eigenstrain_names = ini_stress
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [ini_stress]
    type = ComputeEigenstrainFromInitialStress
    initial_stress = 'steady_state_rr 0 0  0 steady_state_ver 0  0 0 steady_state_tt'
    eigenstrain_name = ini_stress
  []
  [porosity_leaky]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = .2
    block = 1
  []
  [porosity_aquifer]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = .2
    block = 2
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    solid_bulk_compliance = 1E-10
    fluid_bulk_modulus = 2.2E9
  []
  [permeability_leaky]
    type = PorousFlowPermeabilityConst
    permeability = '0 0 0 0 0 0 0 0 0'
    block = 1
  []
  [permeability_aquifer]
    type = PorousFlowPermeabilityConst
    permeability = '9.999999999999999e-14 0 0 0 0 0 0 0 0' # converges nicely
    block = 2
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 2000
  []
[]

[Postprocessors]
  [injection_area]
    type = AreaPostprocessor
    boundary = 'injection_area'
    execute_on = initial
  []
  [pp_0]
    type = PointValue
    point = '0.2 -101 0'
    variable = porepressure
    execute_on = 'TIMESTEP_BEGIN TIMESTEP_END'
  []
  [pp_inf]
    type = PointValue
    point = '1000 -101 0'
    variable = porepressure
    execute_on = 'TIMESTEP_END'
  []
  [flux]
    type = NodalSum
    boundary = 'injection_area'
    variable = fluxes
    execute_on = 'INITIAL NONLINEAR TIMESTEP_END'
  []
  [h]
    type = ScalarVariable
    variable = h
    execute_on = 'NONLINEAR TIMESTEP_END'
  []
  [wellPP]
    type = FunctionValuePostprocessor
    function = wellPP
    execute_on = 'NONLINEAR TIMESTEP_END'
    point = '0.2 -101 0'
  []
  [tidal_head]
    type = FunctionValuePostprocessor
    function = tidal_head
  []
[]

[Preconditioning]
  active = lu
  [basic]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = ' asm      lu           NONZERO                   2'
  []
  [lu]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
  [smp]
    type = SMP
    full = true
    #petsc_options = '-snes_converged_reason -ksp_diagonal_scale -ksp_diagonal_scale_fix -ksp_gmres_modifiedgramschmidt -snes_linesearch_monitor'
    petsc_options_iname = '-ksp_type -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap -snes_atol -snes_rtol -snes_max_it'
    petsc_options_value = 'gmres      hypre     lu           NONZERO                   2               1E-2       1E-8       5000'
  []
[]

[Executioner]
  type = Transient
  solve_type = Newton
  start_time = 0
  end_time = 3456000
  dt = 100
  #nl_abs_tol = 1E-3
  #nl_rel_tol = 1E-10
  # end_time = 172800
  dtmax = 500
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
    growth_factor = 1.1
    #time_t = '0 9 10 90 100 900'
    #time_dt = '1 1 10 10 100 100'
  []
[]

[Outputs]
  csv = true
  #exodus = true
  file_base = gold/2_1.0
[]

[Controls]
  [inject_on]
    type = ConditionalFunctionEnableControl
    enable_objects = 'BCs::out_right'
    conditional_function = inject
    implicit = false
    execute_on = 'initial timestep_begin'
  []
[]

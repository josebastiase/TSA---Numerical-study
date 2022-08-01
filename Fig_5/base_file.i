# A Earth tidal strain is a applied to a large soil colum and porepressure cahnges are saved.
# The column is 1D and fully saturated with water.

[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1000
  xmin = 0
  xmax = 50000
  bias_x = 1.05
[]

[GlobalParams]
  displacements = 'disp_x'
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 1.0
  multiply_by_density = false
[]

[Variables]
  [disp_x]
  []
  [porepressure]
  []
[]

[BCs]

  [strain_y]
    type = FunctionDirichletBC
    variable = disp_x
    function = 0
    boundary = 'left'
  []
  [strain_z]
    type = FunctionDirichletBC
    variable = disp_x
    function = earth_tide_z
    boundary = 'right'
  []
  [pp]
    type = FunctionDirichletBC
    variable = porepressure
    function = 0
    boundary = 'left'
  []
[]

[Functions]
  [earth_tide_z]
    type = ParsedFunction
    value = '1E-8*sin((t)*4*pi/24/3600)*50000'
  []
[]

[Modules]
  [FluidProperties]
    [the_simple_fluid]
      type = SimpleFluidProperties
      bulk_modulus = 2E9
    []
  []
[]

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x'
  porepressure = porepressure
  gravity = '0 0 0'
  fp = the_simple_fluid
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 1E11 # drained bulk modulus
    poissons_ratio = 0.25
  []
  [strain]
    type = ComputeSmallStrain
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [porosity]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = .02
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    solid_bulk_compliance = 1E-11
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1E-12 0 0   0 1E-12 0   0 0 1E-12'
  []
[]

[VectorPostprocessors]
  [pp]
    type = LineValueSampler
    variable = porepressure
    start_point = '0 0 0'
    end_point = '1000 0 0'
    sort_by = x
    num_points = 1000
    execute_on = FINAL
  []
[]
[Postprocessors]
  [pp_0]
    type = PointValue
    point = '0 0 0'
    variable = porepressure
    execute_on = 'TIMESTEP_END'
  []
[]

[Preconditioning]
  [lu]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]

[Executioner]
  type = Transient
  solve_type = Newton
  dt = 3600
  end_time = 442800.0
[]

[Outputs]
    csv = true
    execute_on = FINAL
[]

using LAR
using PyCall
@pyimport larlib as p


function cmerge(models)
	V = hcat([models[k][1] for k=1:length(models)]...)
	shifts = [0]
	append!(shifts, [size(models[h][1],2) for h in 1:length(models)])
	FV = hcat([models[k][2]+shifts[k] for k=1:length(models)]...)
	EV = hcat([models[k][3]+shifts[k] for k=1:length(models)]...)
	return V,FV,EV
end

function boxes2lar(boxes)
	V = Array{Float64,1}[]
	EV = Array{Int64,1}[]
	FV = Array{Int64,1}[]
	for k=1:size(boxes,2)
		xm,ym,xM,yM = boxes[:,k]
		push!(V,[xm,ym])
		push!(V,[xM,yM])
		push!(V,[xm,yM])
		push!(V,[xM,ym])
		push!(EV,[ 4(k-1)+1, 4(k-1)+3 ])
		push!(EV,[ 4(k-1)+1, 4(k-1)+4 ])
		push!(EV,[ 4(k-1)+2, 4(k-1)+3 ])
		push!(EV,[ 4(k-1)+2, 4(k-1)+4 ])
		push!(FV,[ 4(k-1)+1, 4(k-1)+2, 4(k-1)+3, 4(k-1)+4])
	end
	return hcat(V...), hcat(EV...), hcat(FV...)
end

function boxes3lar(boxes)
	V = Array{Float64,1}[]
	EV = Array{Int64,1}[]
	FV = Array{Int64,1}[]
	for k=1:size(boxes,2)
		xm,ym,zm,xM,yM,zM = boxes[:,k]
		push!(V,[xm,ym,zm])
		push!(V,[xM,yM,zm])
		push!(V,[xm,yM,zm])
		push!(V,[xM,ym,zm])
		push!(V,[xm,ym,zM])
		push!(V,[xM,yM,zM])
		push!(V,[xm,yM,zM])
		push!(V,[xM,ym,zM])

		push!(EV,[ 8(k-1)+1, 8(k-1)+3 ])
		push!(EV,[ 8(k-1)+1, 8(k-1)+4 ])
		push!(EV,[ 8(k-1)+2, 8(k-1)+3 ])
		push!(EV,[ 8(k-1)+2, 8(k-1)+4 ])
		push!(EV,[ 8(k-1)+4+1, 8(k-1)+4+3 ])
		push!(EV,[ 8(k-1)+4+1, 8(k-1)+4+4 ])
		push!(EV,[ 8(k-1)+4+2, 8(k-1)+4+3 ])
		push!(EV,[ 8(k-1)+4+2, 8(k-1)+4+4 ])
		push!(EV,[ 8(k-1)+1, 8(k-1)+4+1 ])
		push!(EV,[ 8(k-1)+2, 8(k-1)+4+2 ])
		push!(EV,[ 8(k-1)+3, 8(k-1)+4+3 ])
		push!(EV,[ 8(k-1)+4, 8(k-1)+4+4 ])
		
		push!(FV,[ 8(k-1)+1, 8(k-1)+2, 8(k-1)+3, 8(k-1)+4])
		push!(FV,[ 8(k-1)+4+1, 8(k-1)+4+2, 8(k-1)+4+3, 8(k-1)+4+4])
		push!(FV,[ 8(k-1)+1, 8(k-1)+3, 8(k-1)+4+1, 8(k-1)+4+3])
		push!(FV,[ 8(k-1)+1, 8(k-1)+4, 8(k-1)+4+1, 8(k-1)+4+4])
		push!(FV,[ 8(k-1)+2, 8(k-1)+3, 8(k-1)+4+2, 8(k-1)+4+3])
		push!(FV,[ 8(k-1)+2, 8(k-1)+4, 8(k-1)+4+2, 8(k-1)+4+4])
	end
	return hcat(V...), hcat(EV...), hcat(FV...)
end


params = PyObject(pyeval("list([1.,0.,0.,0.1,  0.,1.,0.,0.1,  0.,0.,1.,0.1, 0.,0.,0.,0.1, 100.])"))
glass = p.MATERIAL(params)

function submanifoldMapping(V::Array{Float64,2},FV::Array{Int64,2},pivotFace::Int64)
	FW = [FV[:,k] for k=1:size(FV,2)]
	return submanifoldMapping(V,FW,pivotFace)
end

#function submanifoldMapping(V::Array{Float64,2},FV::Array{Array{Int64,1},1},pivotFace::Int64)
#    tx,ty,tz = V[:,FV[pivotFace][1]]
#    T = eye(4)
#    T[1,4], T[2,4], T[3,4] = -tx,-ty,-tz
#    facet = [ V[:,v] - [tx,ty,tz] for v in FV[pivotFace] ]
#    normal = normalize(p.COVECTOR(facet)[2:end])
#    a = normal
#    b = Float64[0,0,1]
#    if norm(cross(a,b)) < 10^-5. 
#    	axis = normalize(cross(a,b))
#    else
#    	axis = b
#    end
#    angle = atan2(norm(cross(a,b)), dot(a,b))    
#    # general 3D rotation (Rodrigues' rotation formula)    
#    M = eye(4)
#    Cos, Sin = cos(angle), sin(angle)
#    I, u = eye(3), axis
#    Ux = [0        -u[3]      u[2];
#          u[3]        0      -u[1];
#         -u[2]      u[1]        0]
#    UU = [u[1]*u[1]    u[1]*u[2]    u[1]*u[3] ;
#          u[2]*u[1]    u[2]*u[2]    u[2]*u[3] ;
#          u[3]*u[1]    u[3]*u[2]    u[3]*u[3] ]
#    M[1:3,1:3] = Cos*I + Sin*Ux + (1.0-Cos)*UU
#    transform = M *  T
#    return transform
#end


function submanifoldMapping(V::Array{Float64,2},FV::Array{Array{Int64,1},1},pivotFace::Int64)
    tx,ty,tz = V[:,FV[pivotFace][1]]
    T = eye(4)
    T[1,4], T[2,4], T[3,4] = -tx,-ty,-tz
    facet = [ V[:,v] - [tx,ty,tz] for v in FV[pivotFace] ]
	centroid = p.CCOMB(PyObject(facet))
	u1 = facet[1]-centroid
	u2 = facet[2]-centroid
	u3 = cross(u1,u2)
	M = eye(4)
	M[1:3,1:3] = inv([u1 u2 u3])
    transform = M *  T
    return transform
end




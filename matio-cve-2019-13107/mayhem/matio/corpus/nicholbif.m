% nicholbif.m - this MATLAB file simulates the 
% 2-species Nicholson Bailey difference equation
% modified to include host density dependence:
%       x(n+1) = x(n)*exp(r*(1-x(n)/K)-a*y(n))
%       y(n+1) = x(n)*(1-exp(-a*y(n))) 
% and carries out a bifurcation analysis by varying r.
% 200 different values of a are used between the 
% ranges rmin and rmax set by the user. A bifurcation
% plot is drawn by showing the last 250 points of
% a sequence of 1000 simulated points for each
% value of r. The initial condition is fixed at x0=11, y0=1
a=0.2;       %a=search efficiency of parasitoid
K=22.47;     %K=host carrying capacity
rmin=0.0;  %r=host repro rate
rmax=3;
x0=11;   %initial population x0 of host   
y0=1;   %initial population y0 of parasitoid
n=1000;
jmax=200;
t=zeros(jmax+1,1);
z=zeros(jmax+1,250);
del=(rmax-rmin)/jmax;
for j=1:jmax+1
x=zeros(n+1,1);
y=zeros(n+1,1);
x(1)=x0;
y(1)=y0;
t(j)=(j-1)*del+rmin;
r=t(j);
for i=1:n
x(i+1)=x(i)*exp(r*(1-x(i)/K)-a*y(i));
y(i+1)=x(i)*(1-exp(-a*y(i))); 
if (i>750) 
   z(j,i-750)=x(i+1);
   end
end
end
plot(t,z,'r.','MarkerSize',4)
xlabel('r','FontSize',10), ylabel('Host population','FontSize',10)
title('Bifurcation diagram for the Nicholson-Bailey model')



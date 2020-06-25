% nicholv2.m - this MATLAB file simulates the 
% 2-species Nicholson Bailey difference equation
% modified to include host density dependence:
%       x(n+1) = x(n)*exp(r*(1-x(n)/K)-a*y(n))
%       y(n+1) = x(n)*(1-exp(-a*y(n))) 
r=0.5;    %input('input r=host repro rate:     ')
a=0.2;       %input('input a=search efficiency of parasitoid:     ')
K=14.47;     %input('input K=host carrying capacity:     ')
x0=11;   %input('input initial population x0 of host:     ')
y0=1;   %input('input initial population y0 of parasitoid:     ')
n=80;  %input('input time period of run:     ')
x=zeros(n+1,1);
y=zeros(n+1,1);
t=zeros(n+1,1);
x(1)=x0;
y(1)=y0;
for i=1:n
t(i)=i-1;
x(i+1)=x(i)*exp(r*(1-x(i)/K)-a*y(i));
y(i+1)=x(i)*(1-exp(-a*y(i)));
end
t(n+1)=n;
plot(t,x,t,x,'o')
title('Host values'),pause
plot(t,y,t,y,'*')
title('Parasitoid values'),pause
plot(t,y,t,x,t,x,'o',t,y,'*')
title('Host and parasitoid values'),pause
plot(x,y,'o')
title('Host vs parasitoid');


